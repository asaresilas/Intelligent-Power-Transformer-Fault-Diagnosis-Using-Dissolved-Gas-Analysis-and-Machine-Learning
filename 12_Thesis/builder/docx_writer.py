"""Minimal WordprocessingML (.docx) writer, standard library only.

Layout follows the UMaT "Format for the Presentation of Theses and Project Reports" (May 2011):
A4; margins top/bottom/right 2.54 cm, left 3.05 cm; Times New Roman 12 pt; body 1.5 line spacing;
chapter number 14 pt, chapter title 12 pt, centred; page number centred in the footer; Roman numerals
before Chapter 1. Equations are written as UnicodeMath text in paragraphs of style EqSrc and are built
into Word equations by finish_thesis.ps1 (Word COM), which also updates the page-number fields.
"""
import struct
import zipfile
from xml.sax.saxutils import escape

TWIP_PER_CM = 566.929
EMU_PER_CM = 360000
TEXT_WIDTH_TWIPS = round((21.0 - 3.05 - 2.54) * TWIP_PER_CM)  # 8736

W_NS = ('xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
        'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
        'xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" '
        'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="w14"')


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(33)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"not a PNG: {path}")
    w, h = struct.unpack(">II", head[16:24])
    return w, h


def run_xml(text, bold=False, italic=False, vert=None, size=None, caps=False, font=None):
    """One w:r. vert = 'subscript' | 'superscript'. size in points."""
    rpr = ""
    if font:
        rpr += f'<w:rFonts w:ascii="{font}" w:hAnsi="{font}" w:cs="{font}"/>'
    if bold:
        rpr += "<w:b/><w:bCs/>"
    if italic:
        rpr += "<w:i/><w:iCs/>"
    if caps:
        rpr += "<w:caps/>"
    if size:
        rpr += f'<w:sz w:val="{int(size * 2)}"/><w:szCs w:val="{int(size * 2)}"/>'
    if vert:
        rpr += f'<w:vertAlign w:val="{vert}"/>'
    out = []
    parts = text.split("\t")
    for i, p in enumerate(parts):
        if i:
            out.append("<w:tab/>")
        if p:
            out.append(f'<w:t xml:space="preserve">{escape(p)}</w:t>')
    rp = f"<w:rPr>{rpr}</w:rPr>" if rpr else ""
    return f"<w:r>{rp}{''.join(out)}</w:r>"


def _set_size(runs, szx):
    """Gives every run of a cell the table font size, keeping the schema order of the run properties."""
    def fix(m):
        rpr = m.group(1) or ""
        if "<w:sz " in rpr:
            return m.group(0)
        if "<w:vertAlign" in rpr:
            rpr = rpr.replace("<w:vertAlign", szx + "<w:vertAlign")
        else:
            rpr += szx
        return f"<w:r><w:rPr>{rpr}</w:rPr>"
    import re as _re
    return _re.sub(r"<w:r>(?:<w:rPr>(.*?)</w:rPr>)?", fix, runs)


def field_xml(instr, placeholder="1", bold=False):
    b = "<w:rPr><w:b/></w:rPr>" if bold else ""
    return (f'<w:r>{b}<w:fldChar w:fldCharType="begin"/></w:r>'
            f'<w:r>{b}<w:instrText xml:space="preserve"> {escape(instr)} </w:instrText></w:r>'
            f'<w:r>{b}<w:fldChar w:fldCharType="separate"/></w:r>'
            f'<w:r>{b}<w:t>{escape(placeholder)}</w:t></w:r>'
            f'<w:r>{b}<w:fldChar w:fldCharType="end"/></w:r>')


class Docx:
    def __init__(self):
        self.body = []
        self.media = []      # (zip name, source path)
        self.rels = []       # (rId, type, target)
        self._rid = 10
        self._bm = 0
        self._pic = 0

    # ---------- low level ----------
    def p(self, runs_xml, style=None, jc=None, ind_left=None, ind_hanging=None, ind_first=None,
          before=None, after=None, keep_next=False, keep_lines=False, page_break_before=False,
          line=None, tabs=None, bookmark=None, sect=None, widow=True):
        ppr = ""
        if style:
            ppr += f'<w:pStyle w:val="{style}"/>'
        if keep_next:
            ppr += "<w:keepNext/>"
        if keep_lines:
            ppr += "<w:keepLines/>"
        if page_break_before:
            ppr += "<w:pageBreakBefore/>"
        if tabs:
            ppr += "<w:tabs>" + "".join(
                f'<w:tab w:val="{v}" w:leader="{ld}" w:pos="{pos}"/>' for v, pos, ld in tabs) + "</w:tabs>"
        sp = ""
        if before is not None:
            sp += f' w:before="{before}"'
        if after is not None:
            sp += f' w:after="{after}"'
        if line is not None:
            sp += f' w:line="{line}" w:lineRule="auto"'
        if sp:
            ppr += f"<w:spacing{sp}/>"
        ind = ""
        if ind_left is not None:
            ind += f' w:left="{ind_left}"'
        if ind_hanging is not None:
            ind += f' w:hanging="{ind_hanging}"'
        if ind_first is not None:
            ind += f' w:firstLine="{ind_first}"'
        if ind:
            ppr += f"<w:ind{ind}/>"
        if jc:
            ppr += f'<w:jc w:val="{jc}"/>'
        if sect:
            ppr += sect
        body = runs_xml
        if bookmark:
            self._bm += 1
            body = (f'<w:bookmarkStart w:id="{self._bm}" w:name="{bookmark}"/>' + runs_xml +
                    f'<w:bookmarkEnd w:id="{self._bm}"/>')
        self.body.append(f"<w:p><w:pPr>{ppr}</w:pPr>{body}</w:p>")

    def raw(self, xml):
        self.body.append(xml)

    def page_break(self):
        self.body.append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

    def section_break(self, kind):
        """Ends the current section. kind: 'title' (no page number), 'front' (roman), 'main' (arabic)."""
        self.body.append(f"<w:p><w:pPr>{self.sect_pr(kind)}</w:pPr></w:p>")

    def sect_pr(self, kind):
        foot = ""
        pg = ""
        if kind in ("front", "main"):
            foot = '<w:footerReference w:type="default" r:id="rIdFooter1"/>'
            fmt = "lowerRoman" if kind == "front" else "decimal"
            pg = f'<w:pgNumType w:fmt="{fmt}" w:start="1"/>'
        return (f"<w:sectPr>{foot}<w:pgSz w:w=\"11906\" w:h=\"16838\"/>"
                '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1729" '
                'w:header="709" w:footer="709" w:gutter="0"/>'
                f"{pg}<w:cols w:space=\"708\"/></w:sectPr>")

    def image(self, path, width_cm, max_height_cm=None):
        w, h = png_size(path)
        height_cm = width_cm * h / w
        if max_height_cm and height_cm > max_height_cm:
            height_cm = max_height_cm
            width_cm = height_cm * w / h
        self._pic += 1
        rid = f"rIdImg{self._pic}"
        name = f"media/image{self._pic}.png"
        self.media.append((name, path))
        self.rels.append((rid, "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image", name))
        cx, cy = int(width_cm * EMU_PER_CM), int(height_cm * EMU_PER_CM)
        n = self._pic
        return ('<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
                f'<wp:extent cx="{cx}" cy="{cy}"/><wp:docPr id="{n}" name="Picture {n}"/>'
                '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr>'
                '<a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
                f'<pic:pic><pic:nvPicPr><pic:cNvPr id="{n}" name="image{n}.png"/><pic:cNvPicPr/></pic:nvPicPr>'
                f'<pic:blipFill><a:blip r:embed="{rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
                f'<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm>'
                '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic>'
                '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r>')

    def table(self, rows, header_rows=1, widths=None, font_size=10.5, align=None, bold_first_col=False,
              shade_header=True, keep=False):
        """rows: list of lists of cell run-xml strings. widths in twips (sum <= text width)."""
        ncol = max(len(r) for r in rows)
        if not widths:
            widths = [TEXT_WIDTH_TWIPS // ncol] * ncol
        grid = "".join(f'<w:gridCol w:w="{w}"/>' for w in widths)
        border = ('<w:tblBorders>' + "".join(
            f'<w:{s} w:val="single" w:sz="4" w:space="0" w:color="000000"/>'
            for s in ("top", "left", "bottom", "right", "insideH", "insideV")) + '</w:tblBorders>')
        out = [f'<w:tbl><w:tblPr><w:tblW w:w="{sum(widths)}" w:type="dxa"/><w:jc w:val="center"/>{border}'
               '<w:tblLayout w:type="fixed"/><w:tblCellMar><w:left w:w="70" w:type="dxa"/>'
               '<w:right w:w="70" w:type="dxa"/></w:tblCellMar></w:tblPr>'
               f'<w:tblGrid>{grid}</w:tblGrid>']
        sz = int(font_size * 2)
        for ri, row in enumerate(rows):
            trpr = "<w:trPr><w:cantSplit/>" + ("<w:tblHeader/>" if ri < header_rows else "") + "</w:trPr>"
            cells = []
            for ci in range(ncol):
                content = row[ci] if ci < len(row) else ""
                shade = ('<w:shd w:val="clear" w:color="auto" w:fill="E7E6E6"/>'
                         if (ri < header_rows and shade_header) else "")
                jc = "left"
                if align and ci < len(align):
                    jc = align[ci]
                if ri < header_rows:
                    jc = "center" if (align and ci < len(align) and align[ci] != "left") else "left"
                paras = content.split("\n") if isinstance(content, str) else content
                pxml = ""
                kn = "<w:keepNext/>" if (keep and ri < len(rows) - 1) else ""
                szx = f'<w:sz w:val="{sz}"/><w:szCs w:val="{sz}"/>'
                for para in paras:
                    para = _set_size(para, szx)
                    pxml += (f'<w:p><w:pPr><w:pStyle w:val="TableText"/>{kn}<w:jc w:val="{jc}"/></w:pPr>'
                             f'{para}</w:p>')
                cells.append(f'<w:tc><w:tcPr><w:tcW w:w="{widths[ci]}" w:type="dxa"/>{shade}'
                             f'<w:vAlign w:val="center"/></w:tcPr>{pxml}</w:tc>')
            out.append(f"<w:tr>{trpr}{''.join(cells)}</w:tr>")
        out.append("</w:tbl>")
        self.body.append("".join(out))

    # ---------- package ----------
    def save(self, path, final_section="main"):
        body = "".join(self.body) + self.sect_pr(final_section)
        doc = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
               f'<w:document {W_NS}><w:body>{body}</w:body></w:document>')
        rels = ['<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/'
                'relationships/styles" Target="styles.xml"/>',
                '<Relationship Id="rIdSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/'
                'relationships/settings" Target="settings.xml"/>',
                '<Relationship Id="rIdFooter1" Type="http://schemas.openxmlformats.org/officeDocument/2006/'
                'relationships/footer" Target="footer1.xml"/>']
        for rid, typ, target in self.rels:
            rels.append(f'<Relationship Id="{rid}" Type="{typ}" Target="{target}"/>')
        doc_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                    + "".join(rels) + "</Relationships>")
        footer = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:ftr {W_NS}>'
                  '<w:p><w:pPr><w:pStyle w:val="Footer"/><w:jc w:val="center"/></w:pPr>'
                  + field_xml("PAGE", "1") + "</w:p></w:ftr>")
        ctypes = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                  '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                  '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                  '<Default Extension="xml" ContentType="application/xml"/>'
                  '<Default Extension="png" ContentType="image/png"/>'
                  '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-'
                  'officedocument.wordprocessingml.document.main+xml"/>'
                  '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-'
                  'officedocument.wordprocessingml.styles+xml"/>'
                  '<Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-'
                  'officedocument.wordprocessingml.settings+xml"/>'
                  '<Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-'
                  'officedocument.wordprocessingml.footer+xml"/>'
                  '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-'
                  'package.core-properties+xml"/></Types>')
        root_rels = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                     '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                     '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/'
                     'relationships/officeDocument" Target="word/document.xml"/>'
                     '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/'
                     'metadata/core-properties" Target="docProps/core.xml"/></Relationships>')
        core = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/'
                'core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" '
                'xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
                '<dc:title>MPhil Thesis - Intelligent Power Transformer Fault Diagnosis</dc:title>'
                '</cp:coreProperties>')
        settings = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
                    f'<w:settings {W_NS}><w:updateFields w:val="false"/>'
                    '<w:defaultTabStop w:val="720"/><w:characterSpacingControl w:val="doNotCompress"/>'
                    '<w:compat><w:compatSetting w:name="compatibilityMode" '
                    'w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat></w:settings>')
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("[Content_Types].xml", ctypes)
            z.writestr("_rels/.rels", root_rels)
            z.writestr("docProps/core.xml", core)
            z.writestr("word/document.xml", doc)
            z.writestr("word/_rels/document.xml.rels", doc_rels)
            z.writestr("word/styles.xml", STYLES)
            z.writestr("word/settings.xml", settings)
            z.writestr("word/footer1.xml", footer)
            for name, src in self.media:
                z.write(src, "word/" + name)


def _style(sid, name, ppr="", rpr="", based="Normal", typ="paragraph", nxt=None):
    b = f'<w:basedOn w:val="{based}"/>' if based else ""
    n = f'<w:next w:val="{nxt}"/>' if nxt else ""
    return (f'<w:style w:type="{typ}" w:styleId="{sid}"><w:name w:val="{name}"/>{b}{n}<w:qFormat/>'
            f'<w:pPr>{ppr}</w:pPr><w:rPr>{rpr}</w:rPr></w:style>')


STYLES = ('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          f'<w:styles {W_NS}>'
          '<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" '
          'w:eastAsia="Times New Roman" w:cs="Times New Roman"/><w:sz w:val="24"/><w:szCs w:val="24"/>'
          '<w:lang w:val="en-GB"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr>'
          '<w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>'
          + _style("Normal", "Normal", '<w:widowControl/><w:spacing w:after="200" w:line="360" w:lineRule="auto"/>'
                   '<w:jc w:val="both"/>', "", based=None)
          + _style("Heading1", "heading 1", '<w:keepNext/><w:pageBreakBefore/><w:spacing w:before="0" w:after="360" '
                   'w:line="360" w:lineRule="auto"/><w:jc w:val="center"/><w:outlineLvl w:val="0"/>',
                   "<w:b/><w:bCs/>", nxt="Normal")
          + _style("Heading2", "heading 2", '<w:keepNext/><w:keepLines/><w:spacing w:before="120" w:after="200" '
                   'w:line="360" w:lineRule="auto"/><w:jc w:val="left"/><w:outlineLvl w:val="1"/>',
                   "<w:b/><w:bCs/>", nxt="Normal")
          + _style("Heading3", "heading 3", '<w:keepNext/><w:keepLines/><w:spacing w:before="60" w:after="160" '
                   'w:line="360" w:lineRule="auto"/><w:jc w:val="left"/><w:outlineLvl w:val="2"/>',
                   "", nxt="Normal")
          + _style("Heading4", "heading 4", '<w:keepNext/><w:spacing w:before="60" w:after="120" '
                   'w:line="360" w:lineRule="auto"/><w:jc w:val="left"/><w:outlineLvl w:val="3"/>',
                   "<w:i/><w:iCs/>", nxt="Normal")
          + _style("FrontHeading", "Front Heading", '<w:keepNext/><w:spacing w:before="0" w:after="360" '
                   'w:line="360" w:lineRule="auto"/><w:jc w:val="center"/>', "<w:b/><w:bCs/>")
          + _style("FigCaption", "Figure Caption", '<w:keepLines/><w:spacing w:before="60" w:after="280" '
                   'w:line="276" w:lineRule="auto"/><w:jc w:val="center"/>', "<w:b/><w:bCs/>")
          + _style("TabCaption", "Table Caption", '<w:keepNext/><w:keepLines/><w:spacing w:before="120" w:after="80" '
                   'w:line="276" w:lineRule="auto"/><w:jc w:val="left"/>', "<w:b/><w:bCs/>")
          + _style("FigPara", "Figure", '<w:keepNext/><w:spacing w:before="120" w:after="60" w:line="240" '
                   'w:lineRule="auto"/><w:jc w:val="center"/>', "")
          + _style("TableText", "Table Text", '<w:spacing w:before="20" w:after="20" w:line="240" w:lineRule="auto"/>'
                   '<w:jc w:val="left"/>', '<w:sz w:val="21"/><w:szCs w:val="21"/>')
          + _style("TableNote", "Table Note", '<w:spacing w:before="60" w:after="240" w:line="240" w:lineRule="auto"/>'
                   '<w:jc w:val="left"/>', '<w:sz w:val="21"/><w:szCs w:val="21"/>')
          + _style("EqSrc", "Equation", '<w:keepNext/><w:spacing w:before="120" w:after="120" w:line="276" '
                   'w:lineRule="auto"/><w:jc w:val="center"/>', "")
          + _style("WhereItem", "Where Item", '<w:spacing w:after="40" w:line="276" w:lineRule="auto"/>'
                   '<w:ind w:left="1134" w:hanging="567"/><w:jc w:val="left"/>', "")
          + _style("ListItem", "List Item", '<w:spacing w:after="80" w:line="360" w:lineRule="auto"/>'
                   '<w:ind w:left="720" w:hanging="360"/><w:jc w:val="both"/>', "")
          + _style("RefEntry", "Reference Entry", '<w:spacing w:after="200" w:line="276" w:lineRule="auto"/>'
                   '<w:ind w:left="567" w:hanging="567"/><w:jc w:val="left"/>', "")
          + _style("TocLine", "Contents Line", '<w:spacing w:after="40" w:line="264" w:lineRule="auto"/>'
                   '<w:jc w:val="left"/>', "")
          + _style("Footer", "footer", '<w:spacing w:after="0" w:line="240" w:lineRule="auto"/>', "")
          + _style("TitlePage", "Title Page", '<w:spacing w:after="120" w:line="300" w:lineRule="auto"/>'
                   '<w:jc w:val="center"/>', "")
          + '</w:styles>')
