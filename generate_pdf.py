#!/usr/bin/env python3
"""
Gerador do PDF do projeto BMW F650GS ECU DIY
"""

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm, mm
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT, TA_JUSTIFY
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, HRFlowable, KeepTogether
)
from reportlab.platypus.flowables import Flowable
from reportlab.graphics.shapes import (
    Drawing, Rect, String, Line, Circle,
    Polygon, Group, Path, PolyLine
)
from reportlab.graphics import renderPDF
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from datetime import datetime
import os

# ── Cores do projeto ──────────────────────────────────────────────────────────
PRETO      = HexColor('#0A0A0A')
CINZA_ESC  = HexColor('#1E1E1E')
CINZA_MED  = HexColor('#2A2A2A')
CINZA_CLAR = HexColor('#666666')
BRANCO     = HexColor('#FFFFFF')
AZUL_BMW   = HexColor('#1C69D4')
AZUL_ESC   = HexColor('#0D47A1')
VERMELHO   = HexColor('#C62828')
VERDE      = HexColor('#2E7D32')
LARANJA    = HexColor('#E65100')
AMARELO    = HexColor('#F9A825')
CIANO      = HexColor('#00838F')

W, H = A4  # 595 × 842 pts

OUTPUT = '/home/user/bmwg650s/BMW_F650GS_ECU_DIY.pdf'

# ── Estilos ───────────────────────────────────────────────────────────────────
def build_styles():
    styles = getSampleStyleSheet()

    styles.add(ParagraphStyle(
        'Capa', fontName='Helvetica-Bold', fontSize=28,
        textColor=BRANCO, alignment=TA_CENTER, spaceAfter=6,
        leading=34
    ))
    styles.add(ParagraphStyle(
        'CapaSub', fontName='Helvetica', fontSize=14,
        textColor=HexColor('#90CAF9'), alignment=TA_CENTER, spaceAfter=4
    ))
    styles.add(ParagraphStyle(
        'CapaInfo', fontName='Helvetica', fontSize=10,
        textColor=HexColor('#78909C'), alignment=TA_CENTER
    ))
    styles.add(ParagraphStyle(
        'H1', fontName='Helvetica-Bold', fontSize=18,
        textColor=AZUL_BMW, spaceBefore=18, spaceAfter=8,
        leading=22, borderPadding=(0, 0, 4, 0)
    ))
    styles.add(ParagraphStyle(
        'H2', fontName='Helvetica-Bold', fontSize=13,
        textColor=CINZA_ESC, spaceBefore=12, spaceAfter=6, leading=17
    ))
    styles.add(ParagraphStyle(
        'H3', fontName='Helvetica-Bold', fontSize=11,
        textColor=AZUL_ESC, spaceBefore=8, spaceAfter=4
    ))
    styles.add(ParagraphStyle(
        'Body', fontName='Helvetica', fontSize=9.5,
        textColor=HexColor('#1A1A1A'), spaceAfter=4,
        leading=14, alignment=TA_JUSTIFY
    ))
    styles.add(ParagraphStyle(
        'BulletItem', fontName='Helvetica', fontSize=9.5,
        textColor=HexColor('#1A1A1A'), spaceAfter=2,
        leading=13, leftIndent=12, bulletIndent=0
    ))
    styles.add(ParagraphStyle(
        'CodeBlock', fontName='Courier', fontSize=8,
        textColor=HexColor('#1A1A1A'), backColor=HexColor('#F5F5F5'),
        spaceAfter=6, spaceBefore=4, leading=11,
        leftIndent=8, rightIndent=8, borderPadding=6
    ))
    styles.add(ParagraphStyle(
        'Caption', fontName='Helvetica-Oblique', fontSize=8,
        textColor=CINZA_CLAR, alignment=TA_CENTER, spaceAfter=6
    ))
    styles.add(ParagraphStyle(
        'Aviso', fontName='Helvetica-Bold', fontSize=9,
        textColor=HexColor('#7F0000'), backColor=HexColor('#FFEBEE'),
        spaceAfter=6, spaceBefore=4, leading=13,
        leftIndent=8, rightIndent=8, borderPadding=6
    ))
    styles.add(ParagraphStyle(
        'Dica', fontName='Helvetica', fontSize=9,
        textColor=HexColor('#1B5E20'), backColor=HexColor('#E8F5E9'),
        spaceAfter=6, spaceBefore=4, leading=13,
        leftIndent=8, rightIndent=8, borderPadding=6
    ))
    return styles

S = build_styles()

# ── Helpers ───────────────────────────────────────────────────────────────────
def hr(color=AZUL_BMW, thickness=1):
    return HRFlowable(width='100%', thickness=thickness,
                      color=color, spaceAfter=4, spaceBefore=4)

def sp(h=6):
    return Spacer(1, h)

def h1(txt):  return [sp(4), Paragraph(txt, S['H1']), hr(AZUL_BMW, 1.5)]
def h2(txt):  return [sp(2), Paragraph(txt, S['H2'])]
def h3(txt):  return [sp(1), Paragraph(txt, S['H3'])]
def p(txt):   return Paragraph(txt, S['Body'])
def code(txt): return Paragraph(txt.replace('\n','<br/>').replace(' ','&nbsp;'), S['CodeBlock'])
def aviso(txt): return Paragraph(f'⚠ {txt}', S['Aviso'])
def dica(txt):  return Paragraph(f'✓ {txt}', S['Dica'])
def bul(txt):   return Paragraph(f'• {txt}', S['BulletItem'])

def tabela(dados, col_widths, header=True, zebra=True):
    t = Table(dados, colWidths=col_widths, repeatRows=1 if header else 0)
    style = [
        ('FONTNAME',  (0,0), (-1,0 if header else -1), 'Helvetica-Bold'),
        ('FONTSIZE',  (0,0), (-1,-1), 8.5),
        ('BACKGROUND',(0,0), (-1,0), AZUL_BMW if header else BRANCO),
        ('TEXTCOLOR', (0,0), (-1,0), BRANCO if header else PRETO),
        ('ALIGN',     (0,0), (-1,-1), 'LEFT'),
        ('VALIGN',    (0,0), (-1,-1), 'MIDDLE'),
        ('ROWBACKGROUNDS', (0,1), (-1,-1),
         [HexColor('#F8F9FA'), HexColor('#FFFFFF')] if zebra else [BRANCO]),
        ('GRID',      (0,0), (-1,-1), 0.5, HexColor('#DEE2E6')),
        ('TOPPADDING',(0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING',   (0,0), (-1,-1), 6),
        ('RIGHTPADDING',  (0,0), (-1,-1), 6),
    ]
    t.setStyle(TableStyle(style))
    return t

# ── Diagrama: Arquitetura do Sistema ─────────────────────────────────────────
class ArchDiagram(Flowable):
    def __init__(self, width=460, height=200):
        Flowable.__init__(self)
        self.width  = width
        self.height = height

    def draw(self):
        c = self.canv
        w, h = self.width, self.height

        def box(x, y, bw, bh, fill, stroke, label, sub='', text_color=colors.white):
            c.setFillColor(fill)
            c.setStrokeColor(stroke)
            c.setLineWidth(1.5)
            c.roundRect(x, y, bw, bh, 6, fill=1, stroke=1)
            c.setFillColor(text_color)
            c.setFont('Helvetica-Bold', 8)
            c.drawCentredString(x + bw/2, y + bh/2 + (5 if sub else 1), label)
            if sub:
                c.setFont('Helvetica', 6.5)
                c.setFillColor(HexColor('#BBDEFB') if text_color == colors.white else HexColor('#555555'))
                c.drawCentredString(x + bw/2, y + bh/2 - 6, sub)

        def arrow(x1, y1, x2, y2, label='', color=HexColor('#455A64')):
            c.setStrokeColor(color)
            c.setLineWidth(1.5)
            c.line(x1, y1, x2, y2)
            # arrowhead
            dx, dy = x2 - x1, y2 - y1
            length = (dx**2 + dy**2)**0.5
            if length == 0: return
            ux, uy = dx/length, dy/length
            ax1 = x2 - 8*ux + 4*uy
            ay1 = y2 - 8*uy - 4*ux  # swapped sign
            ax2 = x2 - 8*ux - 4*uy
            ay2 = y2 - 8*uy + 4*ux
            c.setFillColor(color)
            p = c.beginPath()
            p.moveTo(x2, y2)
            p.lineTo(ax1, ay1)
            p.lineTo(ax2, ay2)
            p.close()
            c.drawPath(p, fill=1, stroke=0)
            if label:
                mx, my = (x1+x2)/2, (y1+y2)/2
                c.setFillColor(HexColor('#37474F'))
                c.setFont('Helvetica', 6)
                c.drawCentredString(mx, my + 3, label)

        # Fundo
        c.setFillColor(HexColor('#FAFAFA'))
        c.setStrokeColor(HexColor('#E0E0E0'))
        c.roundRect(0, 0, w, h, 8, fill=1, stroke=1)

        # Título
        c.setFillColor(AZUL_BMW)
        c.setFont('Helvetica-Bold', 9)
        c.drawCentredString(w/2, h - 16, 'ARQUITETURA DO SISTEMA — BMW F650GS ECU DIY')

        bw, bh = 88, 48

        # Coluna 1: Sensores
        sx, sy = 14, h/2 - bh/2 - 10
        box(sx, sy + 50, bw, bh, HexColor('#37474F'), HexColor('#263238'),
            'SENSORES', 'CPS·TPS·MAP\nCLT·IAT·O2·Knock·Óleo')
        c.setFillColor(HexColor('#78909C'))
        c.setFont('Helvetica', 6)
        c.drawCentredString(sx + bw/2, sy + 30, 'Sinais elétricos')

        # Coluna 2: Speeduino
        bx = sx + bw + 38
        box(bx, sy + 30, bw, bh + 20, AZUL_ESC, HexColor('#0D2B6B'),
            'SPEEDUINO', 'Arduino Mega 2560\nECU principal')

        # Coluna 3: ESP32
        ex = bx + bw + 38
        box(ex, sy + 30, bw, bh + 20, HexColor('#00695C'), HexColor('#004D40'),
            'ESP32', 'BLE Bridge\n+ Sensor Óleo')

        # Coluna 4: App
        ax = ex + bw + 38
        box(ax, sy + 30, bw, bh + 20, HexColor('#6A1B9A'), HexColor('#4A148C'),
            'APP FLUTTER', 'Dashboard BLE\nAndroid / iOS')

        # Atuadores (abaixo do Speeduino)
        atx = bx + 8
        box(atx, sy - 28, bw - 16, 30, HexColor('#B71C1C'), HexColor('#7F0000'),
            'ATUADORES', 'Injetor·Bobina·Bomba')

        # Setas
        mid_s  = sy + 50 + bh/2
        mid_sp = sy + 30 + (bh + 20)/2
        mid_e  = sy + 30 + (bh + 20)/2
        mid_a  = sy + 30 + (bh + 20)/2

        arrow(sx + bw, mid_s, bx, mid_sp, 'sinais')
        arrow(bx + bw, mid_sp, ex, mid_e, 'UART\n115200')
        arrow(ex + bw, mid_e, ax, mid_a, 'BLE\n20Hz')

        # Seta para baixo (atuadores)
        arrow(bx + bw/2, sy + 30, bx + bw/2, sy - 28 + 30,
              label='', color=HexColor('#B71C1C'))

        # Legenda protocolo
        c.setFillColor(HexColor('#546E7A'))
        c.setFont('Helvetica', 6.5)
        c.drawString(14, 8, 'Protocolo: ISO 9141-2 / KWP2000 (diagnóstico original) | K-Line 10.400bps')
        c.drawRightString(w - 14, 8, 'Firmware: Speeduino + PlatformIO/FreeRTOS | App: Flutter + flutter_blue_plus')

    def wrap(self, availW, availH):
        return min(self.width, availW), self.height

# ── Diagrama: Pinagem do Conector Diagnóstico ─────────────────────────────────
class ConnectorDiagram(Flowable):
    def __init__(self, width=320, height=160):
        Flowable.__init__(self)
        self.width  = width
        self.height = height

    def draw(self):
        c = self.canv
        w, h = self.width, self.height

        c.setFillColor(HexColor('#F5F5F5'))
        c.setStrokeColor(HexColor('#BDBDBD'))
        c.roundRect(0, 0, w, h, 6, fill=1, stroke=1)

        c.setFillColor(AZUL_BMW)
        c.setFont('Helvetica-Bold', 8)
        c.drawCentredString(w/2, h - 14, 'CONECTOR DIAGNÓSTICO BMW — 10 PINOS (Kostal)')

        # Desenha conector circular
        cx, cy, r = 80, h/2 - 10, 45
        c.setFillColor(HexColor('#37474F'))
        c.setStrokeColor(HexColor('#263238'))
        c.setLineWidth(3)
        c.circle(cx, cy, r, fill=1, stroke=1)

        pins = [
            (1, 'Pino 1', 'K-Line', '#1C69D4', -30),
            (4, 'Pino 4', 'GND',    '#424242', 10),
            (6, 'Pino 6', '+12V',   '#C62828', -10),
            (10,'Pino 10','L-Line\n(não usar)', '#9E9E9E', 30),
        ]

        import math
        angles = [150, 210, 90, 30]
        for i, (num, label, func, col, _) in enumerate(pins):
            ang = math.radians(angles[i])
            px  = cx + (r - 10) * math.cos(ang)
            py  = cy + (r - 10) * math.sin(ang)
            c.setFillColor(HexColor(col))
            c.circle(px, py, 5, fill=1, stroke=0)
            c.setFillColor(colors.white)
            c.setFont('Helvetica-Bold', 5.5)
            c.drawCentredString(px, py - 2, str(num))

        # Tabela ao lado
        rows = [
            ['Pino', 'Cor',       'Função'],
            ['1',    'Marrom/preto', 'K-Line (diagnóstico)'],
            ['4',    'Marrom',     'GND (massa)'],
            ['6',    'Vermelho/branco', '+12V (chave ligada)'],
            ['10',   'Amarelo',    'L-Line (não usar)'],
        ]
        tx, ty = 150, 20
        row_h, col_ws = 18, [25, 80, 115]
        header_cols = [AZUL_BMW, AZUL_BMW, AZUL_BMW]

        for ri, row in enumerate(rows):
            for ci, cell in enumerate(row):
                rx = tx + sum(col_ws[:ci])
                ry = h - ty - (ri + 1) * row_h
                bg = AZUL_BMW if ri == 0 else (HexColor('#F8F9FA') if ri % 2 else BRANCO)
                tc = BRANCO if ri == 0 else PRETO
                c.setFillColor(bg)
                c.setStrokeColor(HexColor('#DEE2E6'))
                c.setLineWidth(0.5)
                c.rect(rx, ry, col_ws[ci], row_h, fill=1, stroke=1)
                c.setFillColor(tc)
                c.setFont('Helvetica-Bold' if ri == 0 else 'Helvetica', 7.5)
                c.drawString(rx + 4, ry + 5, cell)

        c.setFillColor(HexColor('#546E7A'))
        c.setFont('Helvetica-Oblique', 6.5)
        c.drawCentredString(w/2, 8,
            'Localização: acima do radiador, lado direito da moto')

    def wrap(self, availW, availH):
        return min(self.width, availW), self.height

# ── Diagrama: Fiação Simplificada ─────────────────────────────────────────────
class WiringDiagram(Flowable):
    def __init__(self, width=460, height=280):
        Flowable.__init__(self)
        self.width  = width
        self.height = height

    def draw(self):
        c = self.canv
        w, h = self.width, self.height

        c.setFillColor(HexColor('#0D1117'))
        c.roundRect(0, 0, w, h, 8, fill=1, stroke=0)

        c.setFillColor(HexColor('#58A6FF'))
        c.setFont('Helvetica-Bold', 9)
        c.drawCentredString(w/2, h - 16, 'DIAGRAMA DE FIAÇÃO SIMPLIFICADO')

        # Speeduino no centro
        sw, sh = 120, 160
        sx = w/2 - sw/2
        sy = (h - sh)/2 - 10
        c.setFillColor(HexColor('#1C69D4'))
        c.setStrokeColor(HexColor('#58A6FF'))
        c.setLineWidth(1.5)
        c.roundRect(sx, sy, sw, sh, 6, fill=1, stroke=1)
        c.setFillColor(colors.white)
        c.setFont('Helvetica-Bold', 9)
        c.drawCentredString(sx + sw/2, sy + sh - 18, 'SPEEDUINO')
        c.setFont('Helvetica', 7)
        c.setFillColor(HexColor('#BBDEFB'))
        c.drawCentredString(sx + sw/2, sy + sh - 30, 'Arduino Mega 2560')

        # Entradas do Speeduino (lado esquerdo)
        entradas = [
            ('CPS 36-1',   'A0', HexColor('#FFD54F'), sy + sh - 55),
            ('TPS',        'A1', HexColor('#81C784'), sy + sh - 75),
            ('MAP BMP280', 'I2C', HexColor('#4DD0E1'), sy + sh - 95),
            ('CLT (NTC)',  'A2', HexColor('#FF8A65'), sy + sh - 115),
            ('IAT (NTC)',  'A3', HexColor('#CE93D8'), sy + sh - 135),
            ('O2 Wideband','A4', HexColor('#F48FB1'), sy + sh - 155),
        ]
        bx_w = 90
        for label, pin, col, py in entradas:
            bx = sx - bx_w - 22
            c.setFillColor(HexColor('#1E2A3A'))
            c.setStrokeColor(col)
            c.setLineWidth(0.8)
            c.roundRect(bx, py - 7, bx_w, 16, 3, fill=1, stroke=1)
            c.setFillColor(col)
            c.setFont('Helvetica', 7)
            c.drawCentredString(bx + bx_w/2, py - 2, label)
            # linha de conexão
            c.setStrokeColor(col)
            c.setLineWidth(1)
            c.line(bx + bx_w, py + 1, sx, py + 1)
            c.setFillColor(HexColor('#546E7A'))
            c.setFont('Helvetica', 5.5)
            c.drawCentredString(bx + bx_w + 11, py + 4, pin)

        # Saídas do Speeduino (lado direito)
        saidas = [
            ('INJETOR',  'D6',  HexColor('#EF5350'), sy + sh - 55),
            ('BOBINA',   'D8',  HexColor('#FF7043'), sy + sh - 75),
            ('BOMBA',    'D7',  HexColor('#FFA726'), sy + sh - 95),
            ('IAC',      'D4-7',HexColor('#AB47BC'), sy + sh - 115),
            ('KNOCK IN', 'A8',  HexColor('#EC407A'), sy + sh - 135),
        ]
        for label, pin, col, py in saidas:
            bx = sx + sw + 22
            c.setFillColor(HexColor('#1E2A3A'))
            c.setStrokeColor(col)
            c.setLineWidth(0.8)
            c.roundRect(bx, py - 7, 72, 16, 3, fill=1, stroke=1)
            c.setFillColor(col)
            c.setFont('Helvetica', 7)
            c.drawCentredString(bx + 36, py - 2, label)
            c.setStrokeColor(col)
            c.setLineWidth(1)
            c.line(sx + sw, py + 1, bx, py + 1)
            c.setFillColor(HexColor('#546E7A'))
            c.setFont('Helvetica', 5.5)
            c.drawCentredString(sx + sw + 11, py + 4, pin)

        # UART → ESP32
        uart_y = sy + 18
        c.setFillColor(HexColor('#00695C'))
        c.setStrokeColor(HexColor('#80CBC4'))
        c.setLineWidth(1.5)
        esp_x = sx + sw + 22
        c.roundRect(esp_x, uart_y - 4, 72, 28, 4, fill=1, stroke=1)
        c.setFillColor(colors.white)
        c.setFont('Helvetica-Bold', 7.5)
        c.drawCentredString(esp_x + 36, uart_y + 14, 'ESP32')
        c.setFont('Helvetica', 6)
        c.setFillColor(HexColor('#B2DFDB'))
        c.drawCentredString(esp_x + 36, uart_y + 4, 'BLE + Óleo ADC')
        c.setStrokeColor(HexColor('#80CBC4'))
        c.setLineWidth(1.2)
        c.line(sx + sw, uart_y + 12, esp_x, uart_y + 12)
        c.setFillColor(HexColor('#546E7A'))
        c.setFont('Helvetica', 5.5)
        c.drawCentredString(sx + sw + 11, uart_y + 16, 'TX/RX')

        # Bateria (canto superior esquerdo)
        c.setFillColor(HexColor('#1E2A3A'))
        c.setStrokeColor(HexColor('#FFD54F'))
        c.roundRect(14, h - 50, 70, 30, 4, fill=1, stroke=1)
        c.setFillColor(HexColor('#FFD54F'))
        c.setFont('Helvetica-Bold', 8)
        c.drawCentredString(49, h - 30, 'BATERIA 12V')
        c.setFont('Helvetica', 6.5)
        c.drawCentredString(49, h - 42, 'KL30 / KL15 / GND')

        c.setFillColor(HexColor('#546E7A'))
        c.setFont('Helvetica', 6.5)
        c.setFillColor(HexColor('#90A4AE'))
        c.drawString(14, 8,
            'GND: estrela de terra única no bloco do motor  |  '
            'Level shift 5V→3.3V entre Speeduino TX e ESP32 RX')

    def wrap(self, availW, availH):
        return min(self.width, availW), self.height

# ── Diagrama: Orçamento por fase ──────────────────────────────────────────────
class BudgetBar(Flowable):
    def __init__(self, width=420, height=110):
        Flowable.__init__(self)
        self.width  = width
        self.height = height

    def draw(self):
        c = self.canv
        w, h = self.width, self.height

        fases = [
            ('Fase 1\nAliExpress', 421, 741, HexColor('#1C69D4')),
            ('Fase 2\nLocal',      310, 475, HexColor('#00695C')),
            ('Fase 3\nMecânica',   278, 293, HexColor('#6A1B9A')),
        ]
        total_max = 741 + 475 + 293
        bar_h = 28
        start_x = 120
        bar_w   = w - start_x - 20

        c.setFillColor(HexColor('#FAFAFA'))
        c.setStrokeColor(HexColor('#E0E0E0'))
        c.roundRect(0, 0, w, h, 6, fill=1, stroke=1)

        c.setFillColor(AZUL_BMW)
        c.setFont('Helvetica-Bold', 8.5)
        c.drawCentredString(w/2, h - 14, 'ORÇAMENTO POR FASE DE COMPRA (R$)')

        for i, (label, mn, mx, col) in enumerate(fases):
            y = h - 40 - i * (bar_h + 10)

            c.setFillColor(HexColor('#333333'))
            c.setFont('Helvetica', 7.5)
            for j, line in enumerate(label.split('\n')):
                c.drawRightString(start_x - 8, y + bar_h/2 - 4 + j*9, line)

            # fundo cinza
            c.setFillColor(HexColor('#EEEEEE'))
            c.roundRect(start_x, y, bar_w, bar_h, 3, fill=1, stroke=0)

            # barra mínimo
            bw_mn = int(bar_w * mn / total_max)
            c.setFillColor(col)
            c.roundRect(start_x, y, bw_mn, bar_h, 3, fill=1, stroke=0)

            # barra máximo (overlap)
            bw_mx = int(bar_w * mx / total_max)
            lighter = HexColor(
                '#%02x%02x%02x' % tuple(
                    min(255, int(v * 1.4)) for v in
                    bytes.fromhex(col.hexval()[2:])  # hexval() returns '0x...'
                )
            )
            c.setFillColor(lighter)
            c.setFillAlpha(0.4)
            c.roundRect(start_x + bw_mn, y, bw_mx - bw_mn, bar_h, 3, fill=1, stroke=0)
            c.setFillAlpha(1.0)

            # labels
            c.setFillColor(colors.white)
            c.setFont('Helvetica-Bold', 8)
            c.drawString(start_x + 6, y + bar_h/2 - 4, f'R${mn}–{mx}')

        # Total
        y = h - 40 - 3 * (bar_h + 10)
        c.setFillColor(HexColor('#444444'))
        c.setFont('Helvetica-Bold', 8.5)
        c.drawRightString(start_x - 8, y + 10, 'TOTAL')
        c.setFillColor(AZUL_BMW)
        c.drawString(start_x + 6, y + 10,
                     'R$ 1.009 – R$ 1.509  |  ECU BMW original usada: R$800–2.000 (sem mapeamento)')

    def wrap(self, availW, availH):
        return min(self.width, availW), self.height

# ── Capa ──────────────────────────────────────────────────────────────────────
class CoverPage(Flowable):
    def __init__(self, width=W, height=H):
        Flowable.__init__(self)
        self.width  = width
        self.height = height

    def wrap(self, availW, availH):
        return availW, availH

    def drawOn(self, canvas, x, y, _sW=0):
        # Draw at absolute page origin (bypass frame translation)
        canvas.saveState()
        self.canv = canvas
        self.draw()
        canvas.restoreState()

    def draw(self):
        c = self.canv
        w, h = W, H  # always full page

        # Fundo degradê simulado
        for i in range(100):
            t = i / 100
            r = int(10 + t * 18)
            g = int(10 + t * 50)
            b = int(20 + t * 80)
            c.setFillColorRGB(r/255, g/255, b/255)
            c.rect(0, h * i/100, w, h/100 + 1, fill=1, stroke=0)

        # Faixa azul superior
        c.setFillColor(AZUL_BMW)
        c.rect(0, h - 80, w, 80, fill=1, stroke=0)

        # Faixa branca estreita
        c.setFillColor(BRANCO)
        c.rect(0, h - 84, w, 4, fill=1, stroke=0)

        # Logo BMW simulado (círculos)
        lx, ly, lr = 60, h - 42, 30
        c.setFillColor(colors.white)
        c.circle(lx, ly, lr, fill=1, stroke=0)
        c.setFillColor(AZUL_BMW)
        for angle, fill in [(45, True), (225, True)]:
            import math
            a = math.radians(angle)
            c.setFillColor(AZUL_BMW)
            path = c.beginPath()
            path.moveTo(lx, ly)
            path.arcTo(lx - lr, ly - lr, lx + lr, ly + lr,
                       angle, 90)
            path.close()
            c.drawPath(path, fill=1, stroke=0)

        c.setFillColor(colors.white)
        c.setFont('Helvetica-Bold', 11)
        c.drawCentredString(lx, ly - 4, 'BMW')

        # Título
        c.setFillColor(colors.white)
        c.setFont('Helvetica-Bold', 32)
        c.drawCentredString(w/2 + 20, h - 55, 'BMW F650GS — ECU DIY')
        c.setFont('Helvetica', 14)
        c.setFillColor(HexColor('#90CAF9'))
        c.drawCentredString(w/2 + 20, h - 72, 'Sistema de Injeção Eletrônica com Dashboard Bluetooth')

        # Placa central decorativa
        c.setFillColor(HexColor('#0D2B6B'))
        c.setStrokeColor(HexColor('#1C69D4'))
        c.setLineWidth(2)
        c.roundRect(w/2 - 190, h/2 - 30, 380, 180, 12, fill=1, stroke=1)

        items = [
            ('Microcontrolador', 'Speeduino (Arduino Mega) + ESP32'),
            ('Conectividade',    'Bluetooth BLE → App Android/iOS'),
            ('Dashboard',        'Tacômetro · AFR · Temps · Óleo · Knock'),
            ('Mapeamento',       'Tabela VE 16×16 editável no celular'),
            ('Diagnóstico',      'Leitor K-Line da ECU original (BMS-C)'),
        ]
        c.setFont('Helvetica-Bold', 9)
        c.setFillColor(HexColor('#64B5F6'))
        c.drawCentredString(w/2, h/2 + 130, '● CARACTERÍSTICAS DO PROJETO ●')

        for i, (k, v) in enumerate(items):
            y = h/2 + 108 - i * 22
            c.setFillColor(HexColor('#42A5F5'))
            c.setFont('Helvetica-Bold', 8.5)
            c.drawRightString(w/2 - 4, y, k + ':')
            c.setFillColor(colors.white)
            c.setFont('Helvetica', 8.5)
            c.drawString(w/2 + 4, y, v)

        # Motor info
        c.setFillColor(HexColor('#0A3060'))
        c.roundRect(w/2 - 140, h/2 - 26, 280, 38, 8, fill=1, stroke=0)
        c.setFillColor(AZUL_BMW)
        c.setFont('Helvetica-Bold', 11)
        c.drawCentredString(w/2, h/2 - 2, 'Motor: Rotax 654cc · Monocilíndrico')
        c.setFillColor(HexColor('#90CAF9'))
        c.setFont('Helvetica', 9)
        c.drawCentredString(w/2, h/2 - 16, 'ECU original: BMW BMS-C (Bosch Motronic MA 2.4)')

        # Rodapé
        c.setFillColor(HexColor('#1A1A1A'))
        c.rect(0, 0, w, 50, fill=1, stroke=0)
        c.setFillColor(BRANCO)
        c.setFont('Helvetica-Bold', 9)
        c.drawCentredString(w/2, 32, 'Projeto Open Source — Documentação Técnica Completa')
        c.setFillColor(HexColor('#78909C'))
        c.setFont('Helvetica', 8)
        c.drawCentredString(w/2, 18,
            f'Gerado em {datetime.now().strftime("%d/%m/%Y")}  |  '
            'Repositório: github.com/gustavowalkersgroup/bmwg650s')


# ── Cabeçalho/Rodapé nas páginas ─────────────────────────────────────────────
def on_page(canvas_obj, doc):
    if doc.page == 1:
        return  # cover page draws its own header/footer
    canvas_obj.saveState()
    # Rodapé
    canvas_obj.setFillColor(HexColor('#1C69D4'))
    canvas_obj.rect(0, 0, W, 22, fill=1, stroke=0)
    canvas_obj.setFillColor(colors.white)
    canvas_obj.setFont('Helvetica', 7)
    canvas_obj.drawString(2*cm, 7,
        'BMW F650GS — ECU DIY com Dashboard Bluetooth')
    canvas_obj.drawRightString(W - 2*cm, 7,
        f'Pág. {doc.page}')
    # Cabeçalho
    canvas_obj.setFillColor(AZUL_BMW)
    canvas_obj.rect(0, H - 26, W, 26, fill=1, stroke=0)
    canvas_obj.setFillColor(colors.white)
    canvas_obj.setFont('Helvetica-Bold', 8)
    canvas_obj.drawString(2*cm, H - 16,
        'BMW F650GS · ECU DIY · Speeduino + ESP32 + Flutter')
    canvas_obj.drawRightString(W - 2*cm, H - 16,
        'Documentação Técnica v1.0')
    canvas_obj.restoreState()


# ── Monta o documento ─────────────────────────────────────────────────────────
def build_pdf():
    doc = SimpleDocTemplate(
        OUTPUT,
        pagesize=A4,
        rightMargin=2*cm, leftMargin=2*cm,
        topMargin=2.2*cm, bottomMargin=1.8*cm,
        title='BMW F650GS ECU DIY',
        author='Gustavo Walker',
        subject='Sistema de Injeção Eletrônica com Dashboard Bluetooth',
    )

    story = []

    # ── CAPA ──────────────────────────────────────────────────────────────────
    story.append(CoverPage())
    story.append(PageBreak())

    # ── 1. VISÃO GERAL ────────────────────────────────────────────────────────
    story += h1('1. Visão Geral do Projeto')
    story.append(p(
        'A BMW F650GS 2001 utiliza a ECU original <b>BMS-C</b> (BMW Motorrad System Classic), '
        'baseada no Bosch Motronic MA 2.4. Quando essa ECU apresenta falhas, a substituição '
        'oficial custa entre <b>R$800 e R$2.000</b> por uma unidade usada, sem garantia e sem '
        'qualquer possibilidade de mapeamento ou diagnóstico avançado.'
    ))
    story.append(p(
        'Este projeto substitui a ECU original por um sistema open-source baseado no '
        '<b>Speeduino</b> (Arduino Mega 2560), com comunicação Bluetooth via <b>ESP32</b> e '
        'um aplicativo Flutter que funciona como painel digital completo — similar ao '
        '<b>FuelTech F700</b> — diretamente no celular do proprietário.'
    ))
    story.append(sp(6))
    story.append(ArchDiagram(width=460, height=200))
    story.append(Paragraph('Fig. 1 — Arquitetura completa do sistema', S['Caption']))
    story.append(sp(4))

    story += h2('Objetivos')
    for item in [
        'Substituir a ECU com defeito por solução econômica e mapeável (~R$537 fase inicial)',
        'Manter todas as funções originais: injeção sequencial, ignição, marcha lenta (IAC)',
        'Adicionar recursos novos: sensor de knock, pressão de óleo, velocímetro VSS',
        'Dashboard em tempo real via Bluetooth no celular (tacômetro, AFR, temps, óleo)',
        'Editor de mapas VE/Ignição 16×16 diretamente no app',
        'Leitor de diagnóstico da ECU original antes da substituição',
    ]:
        story.append(bul(item))

    # ── 2. ESPECIFICAÇÕES F650GS ──────────────────────────────────────────────
    story += h1('2. Especificações Técnicas da BMW F650GS 2001')

    story += h2('Motor e Sistema de Injeção')
    dados_motor = [
        ['Parâmetro',              'Valor'],
        ['Motor',                  'Rotax 654cc, monocilíndrico, 4 tempos'],
        ['Configuração',           '4 válvulas, SOHC, refrigerado a líquido'],
        ['Diâmetro × curso',       '100 mm × 83 mm'],
        ['Taxa de compressão',     '11,5:1'],
        ['Potência máxima',        '50 cv @ 6.500 RPM'],
        ['Torque máximo',          '60 Nm @ 5.000 RPM'],
        ['RPM de marcha lenta',    '1.200–1.400 RPM'],
        ['RPM limiter',            '~7.500 RPM'],
        ['ECU original',           'BMW BMS-C (Bosch Motronic MA 2.4)'],
        ['Roda fônica',            '36-1 dentes no virabrequim'],
        ['Injetor',                'Bosch EV1, ~270 cc/min @ 3 bar, 12–16 Ω'],
        ['Pressão de combustível', '3,0 bar'],
        ['Ignição',                'Bobina indutiva, faísca desperdiçada'],
        ['Sensor O2 original',     'Bosch LSM11 — narrowband (0,1–0,9V)'],
    ]
    story.append(tabela(dados_motor, [6*cm, 10*cm]))

    story.append(sp(8))
    story += h2('Sensores (Original + Adicionados)')
    dados_sensores = [
        ['Sensor',            'Tipo',              'Pino Speeduino', 'Observação'],
        ['CPS (virabrequim)', 'VR indutivo (36-1)','VR+ / VR−',      'Requer VR conditioner (MAX9926)'],
        ['TPS',               'Potenciômetro 0–5V','A0',             '~0,4V fechado / ~4,6V aberto'],
        ['MAP',               'BMP280 I2C',        'SDA/SCL',        'Substitui MPX4250, R$12'],
        ['CLT',               'NTC termistor',     'A2',             '~2500Ω @ 25°C'],
        ['IAT',               'NTC termistor',     'A3',             'Mesma curva do CLT'],
        ['O2 Wideband',       'LSU 4.9 + CJ125',   'A4',             'Substitui narrowband original'],
        ['Knock',             'Piezo Bosch M8',    'KNOCK',          'Retardo automático pelo Speeduino'],
        ['Pressão de óleo',   'Analógico 0–10 bar','ESP32 GPIO34',   'Lido pelo ESP32, não Speeduino'],
        ['VSS',               'Hall effect',       'VSS',            'Velocidade em km/h'],
    ]
    story.append(tabela(dados_sensores,
                        [3.2*cm, 3.2*cm, 3.0*cm, 6.6*cm]))

    # ── 3. ARQUITETURA DE HARDWARE ────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('3. Arquitetura de Hardware')

    story += h2('Por que Speeduino + ESP32?')
    story.append(p(
        'O <b>ESP32 sozinho</b> poderia controlar a injeção de um monocilíndrico, porém apresenta '
        'dois problemas críticos para uso em ECU: (1) o ADC interno tem ruído de ~50–100 mV que '
        'compromete leitura do MAP e TPS; (2) os serviços BLE/WiFi causam jitter nos timers, '
        'o que pode adiantar ou atrasar o ponto de ignição em microsegundos — inaceitável '
        'em motor com taxa 11,5:1.'
    ))
    story.append(p(
        'O <b>Speeduino</b> é um firmware open-source maduro, testado em centenas de motos '
        'monocilíndricas com roda fônica 36-1. O ESP32 fica dedicado à comunicação BLE e '
        'leitura do sensor de pressão de óleo, sem interferir no timing crítico da ECU.'
    ))

    story.append(sp(8))
    story += h2('Conector de Diagnóstico Original (BMS-C)')
    story.append(ConnectorDiagram(width=380, height=155))
    story.append(Paragraph('Fig. 2 — Conector diagnóstico BMW 10-pin (Kostal) e pinagem', S['Caption']))

    story.append(sp(8))
    story += h2('Diagrama de Fiação')
    story.append(WiringDiagram(width=490, height=270))
    story.append(Paragraph('Fig. 3 — Diagrama de fiação simplificado (ver docs/wiring-diagram.md para detalhes completos)', S['Caption']))

    story.append(sp(6))
    story.append(aviso(
        'ATENÇÃO DE SEGURANÇA: Todos os GNDs de sensores devem convergir em um único ponto de '
        'aterramento no bloco do motor (estrela de terra). Terra mal feito é a principal causa '
        'de leituras erráticas em ECUs DIY.'
    ))

    # ── 4. FIRMWARE ESP32 ─────────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('4. Firmware ESP32 — BLE Bridge')

    story.append(p(
        'O firmware do ESP32 usa <b>FreeRTOS dual-core</b>: o Core 0 gerencia a comunicação '
        'serial com o Speeduino (protocolo proprietário Speeduino, comando \'A\', 38 bytes), '
        'e o Core 1 gerencia as notificações BLE a 20Hz para o app.'
    ))

    story += h2('Pacote BLE (24 bytes, 20Hz)')
    dados_pkt = [
        ['Byte(s)', 'Campo',        'Descrição'],
        ['0–1',     'rpm',          'RPM (uint16, little-endian)'],
        ['2',       'tps',          'TPS 0–100%'],
        ['3',       'map_kpa',      'MAP em kPa'],
        ['4',       'clt_c',        'Temperatura água °C (int8, offset -40)'],
        ['5',       'iat_c',        'Temperatura ar °C (int8, offset -40)'],
        ['6',       'afr10',        'AFR ×10 (147 = 14,7)'],
        ['7',       'afr_tgt10',    'AFR alvo ×10'],
        ['8',       'adv',          'Avanço ignição graus BTDC (int8)'],
        ['9',       'batt10',       'Tensão bateria ×10 (138 = 13,8V)'],
        ['10',      've',           'VE atual %'],
        ['11',      'pw_ms10',      'Largura pulso injetor ×0,1ms'],
        ['12',      'idle_duty',    'IAC duty cycle %'],
        ['13',      'sync',         '0 = sincronizado, 1 = sem sync'],
        ['14',      'alarms',       'Bitfield: CLT|RPM|BATT|LEAN|RICH|OIL|KNOCK'],
        ['15–18',   'corr/flex/baro/loop', 'Dados complementares'],
        ['19',      'speed_kmh',    'Velocidade km/h (VSS)'],
        ['20',      'oil_press10',  'Pressão óleo ×10 bar (ESP32 GPIO34)'],
        ['21',      'knock_ret',    'Retardo knock em graus'],
        ['22–23',   'reserved',     'Reservado'],
    ]
    story.append(tabela(dados_pkt, [1.8*cm, 3*cm, 10.2*cm]))

    story.append(sp(6))
    story += h2('Alarmes Automáticos')
    dados_alm = [
        ['Alarme',             'Condição',                              'Bit'],
        ['Temperatura alta',   'CLT ≥ 105°C',                          'bit 0'],
        ['RPM limiter',        'RPM ≥ 7.400',                          'bit 1'],
        ['Bateria baixa',      'Vbatt < 11,8V',                        'bit 2'],
        ['Mistura pobre',      'MAP > 40 kPa e AFR > 16,0',            'bit 3'],
        ['Mistura rica',       'MAP > 40 kPa e AFR < 10,5',            'bit 4'],
        ['Óleo baixo',         'RPM > 1.500 e pressão < 0,8 bar',      'bit 5'],
        ['Detonação',          'Knock retard ≥ 2°',                    'bit 6'],
    ]
    story.append(tabela(dados_alm, [4*cm, 8*cm, 2*cm]))

    # ── 5. APP FLUTTER ────────────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('5. Aplicativo Flutter — Dashboard')

    story.append(p(
        'O app conecta via BLE ao ESP32, recebe os dados a 20Hz e exibe em tempo real. '
        'Tema escuro estilo painel automotivo. Compatível com Android e iOS.'
    ))

    story += h2('Telas do Aplicativo')
    dados_telas = [
        ['Tela',          'Componentes principais'],
        ['Dashboard',     'Tacômetro circular 0–8000 RPM (SfRadialGauge), AFR gauge com faixas coloridas, '
                          'temperatura água/ar (barras verticais), 2 linhas de dados numéricos: '
                          'TPS · MAP · ADV · VE · BATT · SYNC e ÓLEO · VEL · KNOCK · FLEX · LOOP'],
        ['Editor Mapas',  'Tabela VE 16×16 com gradiente de cores azul→verde→vermelho (igual TunerStudio). '
                          'Tap em célula abre diálogo de edição. Tab de ignição (mapa de avanço)'],
        ['Log em Tempo Real', 'Três gráficos sobrepostos: RPM (vermelho), AFR (verde), MAP (azul). '
                              'Histórico de 6 segundos a 20Hz. Linha de referência AFR 14,7'],
    ]
    story.append(tabela(dados_telas, [3.2*cm, 11.8*cm]))

    story.append(sp(6))
    story += h2('Dependências Flutter (pubspec.yaml)')
    pkgs = [
        ('flutter_blue_plus ^1.31',   'BLE scan, connect, notify'),
        ('syncfusion_flutter_gauges',  'Tacômetro e gauges radiais'),
        ('fl_chart ^0.68',             'Gráficos de linha em tempo real'),
        ('provider ^6.1',              'Gerenciamento de estado (BleService)'),
        ('shared_preferences ^2.3',    'Persistência de configurações'),
        ('path_provider + csv',        'Log de dados em arquivo CSV'),
        ('permission_handler ^11.3',   'Permissões BLE no Android/iOS'),
    ]
    story.append(tabela(
        [['Pacote', 'Uso']] + [[p, u] for p, u in pkgs],
        [7*cm, 8*cm]
    ))

    # ── 6. DIAGNÓSTICO ECU ORIGINAL ───────────────────────────────────────────
    story.append(PageBreak())
    story += h1('6. Diagnóstico da ECU Original (BMS-C)')

    story.append(p(
        '<b>Antes de substituir qualquer componente</b>, execute o diagnóstico completo da ECU '
        'original. Os códigos de falha indicam exatamente o que está quebrado — pode ser apenas '
        'um sensor de R$30 e não a ECU.'
    ))

    story += h2('Protocolo da BMS-C (verificado em múltiplas fontes)')
    dados_proto = [
        ['Parâmetro',        'Valor'],
        ['Camada física',    'ISO 9141-2 (K-Line, half-duplex)'],
        ['Protocolo',        'ISO 14230-4 KWP2000 (Keyword Protocol 2000)'],
        ['Fios necessários', '3: K-Line (pino 1), GND (pino 4), +12V (pino 6)'],
        ['L-Line (pino 10)', 'Não necessário na F650GS'],
        ['Baud rate',        '10.400 bps após inicialização'],
        ['Init',             '5-baud slow init ou KWP2000 fast init'],
        ['Conector',         'Kostal 10-pin — acima do radiador, lado direito'],
    ]
    story.append(tabela(dados_proto, [5*cm, 10*cm]))

    story.append(sp(6))
    story += h2('Kit de Diagnóstico Recomendado (~R$250)')
    story.append(p(
        'A ferramenta <b>MotoScan</b> (app Android) já implementou a engenharia reversa do '
        'protocolo BMW — não é necessário desenvolver nada do zero para diagnóstico.'
    ))
    dados_kit = [
        ['Componente',        'Especificação',                    'Preço est.'],
        ['App MotoScan',      'Android (Google Play)',             'R$20'],
        ['OBDLink LX',        'Bluetooth, suporte ISO 9141',       'R$150'],
        ['Cabo 10-pin → OBD2','BMW ICOM-D adapter motorcycle',     'R$60–80'],
        ['TOTAL',             '',                                  'R$230–250'],
    ]
    story.append(tabela(dados_kit, [4.5*cm, 7*cm, 3.5*cm]))

    story.append(sp(6))
    story += h2('O que o MotoScan Lê na F650GS')
    for item in [
        'Códigos de falha (DTC) com descrição em texto — leitura e limpeza',
        'RPM, TPS, CLT, IAT, MAP, O2 Lambda em tempo real',
        'Tensão da bateria, carga do motor, avanço de ignição',
        'Teste de atuadores: injetor, bobina, válvula IAC',
        'Reset de adaptações (obrigatório após troca de sensor)',
        'Congelamento de quadro (freeze frame) no momento da falha',
    ]:
        story.append(bul(item))

    story.append(sp(6))
    story += h2('Códigos de Falha Mais Comuns na F650GS (Comunidade)')
    dados_dtc = [
        ['Sintoma',                    'Código / Causa provável'],
        ['Sem faísca / não parte',     'CPS com defeito ou sem sinal, bobina aberta'],
        ['Marcha lenta instável',      'TPS descalibrado, válvula IAC travada'],
        ['Fumaça preta / consumo alto','Sonda O2 defeituosa, injetor com vazamento'],
        ['Morre em aceleração',        'TPS, MAP ou injetor com falha intermitente'],
        ['Luz check acesa',            'Código travado — limpar e monitorar'],
        ['Partida difícil a frio',     'Sensor CLT fora de curva, enriquecimento incorreto'],
    ]
    story.append(tabela(dados_dtc, [6*cm, 9*cm]))

    story.append(sp(4))
    story.append(dica(
        'DICA: Conecte o MotoScan com o motor quente e em marcha lenta por 10 minutos '
        'antes de ler os códigos. Falhas intermitentes só aparecem quando o motor está '
        'na temperatura de operação.'
    ))

    # ── 7. GUIA DE CALIBRAÇÃO ─────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('7. Guia de Calibração — Speeduino + TunerStudio')

    story += h2('Configurações Críticas no TunerStudio')
    dados_ts = [
        ['Parâmetro',           'Valor para F650GS'],
        ['Trigger Pattern',     'Missing Tooth (36-1)'],
        ['Teeth Total',         '36'],
        ['Missing Teeth',       '1'],
        ['Trigger Angle',       '54° (verificar com estroboscópio)'],
        ['Trigger Edge',        'Falling (sensor VR indutivo)'],
        ['Injection Type',      'Sequential'],
        ['Cylinders',           '1'],
        ['Spark Mode',          'Wasted Spark'],
        ['Dwell Time',          '3,5 ms'],
        ['Injector Flow',       '270 cc/min @ 3 bar'],
        ['Displacement',        '654 cc'],
        ['MAP Sensor',          'BMP280 (I2C) ou MPX4250'],
        ['O2 Type',             'Wideband Linear 0–5V → AFR 10–20'],
        ['Hard Cut RPM',        '7.500 RPM'],
        ['Serial Speed',        '115.200 baud'],
    ]
    story.append(tabela(dados_ts, [5.5*cm, 9.5*cm]))

    story.append(sp(8))
    story += h2('Alvos de AFR por Condição')
    dados_afr = [
        ['Condição',           'AFR Alvo',   'Lambda', 'Observação'],
        ['Partida fria',       '10–12',       '0,68–0,82', 'Enriquecimento automático por CLT'],
        ['Aquecimento',        '12–13',       '0,82–0,89', 'Reduz conforme CLT sobe'],
        ['Marcha lenta quente','14,5–15,0',   '0,99–1,02', 'Eficiência máxima + emissões'],
        ['Cruzeiro parcial',   '14,5–15,5',   '0,99–1,06', 'Economia de combustível'],
        ['Aceleração moderada','13,0–14,0',   '0,89–0,96', 'Resposta sem detonação'],
        ['WOT (pleno)',        '12,5–13,2',   '0,85–0,90', 'Potência máxima segura'],
        ['Desaceleração',      'Corte inject.','—',        'Fuel cut acima de 1.500 RPM'],
    ]
    story.append(tabela(dados_afr, [4*cm, 2.8*cm, 2.5*cm, 5.7*cm]))

    story.append(sp(6))
    story += h2('Procedimento de Primeira Partida')
    passos = [
        'Verificar pressão de combustível no rail: 3,0 ± 0,2 bar',
        'Confirmar prime da bomba ao ligar a chave (funciona 2s)',
        'Verificar comunicação TunerStudio → ECU (indicador online)',
        'Confirmar MAP: ~100 kPa com motor parado',
        'Confirmar CLT: temperatura ambiente (~20–30°C)',
        'Acionar motor de partida brevemente (2–3s)',
        'Se partir: manter RPM com acelerador até aquecer (~1 min)',
        'Monitorar AFR no app: deve ficar entre 12–15 nos primeiros minutos',
        'Se AFR > 16 (muito pobre): aumentar req_fuel em +10–20%',
        'Se AFR < 11 (muito rico): diminuir req_fuel em 10–20%',
    ]
    for i, p_item in enumerate(passos):
        story.append(Paragraph(f'{i+1}. {p_item}', S['BulletItem']))

    # ── 8. LISTA DE MATERIAIS ─────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('8. Lista de Materiais Completa (BOM)')

    story += h2('Componentes Principais')
    bom1 = [
        ['#', 'Componente',                  'Especificação',                      'Qtd', 'Preço (R$)'],
        ['1',  'Arduino Mega 2560',           'Clone — Mercado Livre / FilipeFlop', '1',  '60–90'],
        ['2',  'Speeduino Shield v0.4.4c',    'Kit ou montado — speeduino.com',     '1',  '150–300'],
        ['3',  'ESP32-WROOM-32 DevKit',       '38 pinos — FilipeFlop / ML',         '1',  '35–50'],
        ['4',  'Sensor MAP BMP280',           'I2C, 0–110 kPa — AliExpress',        '1',  '12–18'],
        ['5',  'Controlador Wideband CJ125',  'Kit PCB — AliExpress',               '1',  '80–150'],
        ['6',  'Sonda Lambda LSU 4.9',        'Bosch 0 258 017 025',                '1',  '120–200'],
    ]
    story.append(tabela(bom1, [0.8*cm, 4.2*cm, 5*cm, 1*cm, 3*cm]))

    story.append(sp(6))
    story += h2('Sensores Adicionais (Knock + Óleo + VSS)')
    bom2 = [
        ['#', 'Componente',                  'Especificação',                       'Preço (R$)'],
        ['A1', 'Sensor Knock',               'Bosch 0 261 231 006, M8 plano',       '30–50'],
        ['A2', 'Sender Pressão de Óleo',     '0–10 bar, 0,5–4,5V, 1/8" NPT',       '35–60'],
        ['A3', 'Adaptador Rosca Óleo',       'M10×1,0 fêmea → 1/8" NPT macho',     '15–25'],
        ['A4', 'Sensor VSS Hall',            '3 fios, Hall, 5V — AliExpress',       '20–35'],
    ]
    story.append(tabela(bom2, [0.8*cm, 4*cm, 6*cm, 3.2*cm]))

    story.append(sp(6))
    story += h2('Eletrônicos, Conectores e Proteção')
    bom3 = [
        ['Componente',                    'Especificação',                   'Preço (R$)'],
        ['MOSFET IRFZ44N ×2',             'N-channel, TO-220',               '5'],
        ['Transistor BIP373',             'Transistor ignição',               '10'],
        ['Diodo TVS P6KE18A ×2',          'Proteção bobina',                 '5'],
        ['Resistores + capacitores',      'Kit básico 150Ω/2k49/10k/100nF',  '15'],
        ['Level shifter 5V↔3,3V',         '4 canais bidirecional',           '8'],
        ['Kit conector AMP Superseal',    '2 a 12 pinos, com terminais',     '80–120'],
        ['Fio automotivo 0,5mm² × 5 cores','Rolos 10m',                     '80'],
        ['Fio automotivo 1,5mm² × 2',     'Para alimentação',                '30'],
        ['Manga termorretrátil + fita',    'Kit 3mm e 6mm',                  '25'],
        ['Caixa estanque IP65',           '150×100×70mm, ABS',               '35–50'],
        ['Relé 30A × 3 + fusíveis',       'Com socket, lâmina ATO/MAXI',     '43'],
    ]
    story.append(tabela(bom3, [5*cm, 6*cm, 3*cm]))

    story.append(sp(8))
    story.append(BudgetBar(width=450, height=115))
    story.append(Paragraph('Fig. 4 — Orçamento total por fase de compra', S['Caption']))

    # ── 9. PLANO DE COMPRA ────────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('9. Plano de Compra por Fases')

    story.append(p(
        'O projeto pode ser executado em 3 fases independentes, permitindo distribuir '
        'o investimento ao longo do tempo e validar cada etapa antes de continuar.'
    ))

    story += h2('Fase 1 — Pedido Imediato (AliExpress, 3–5 semanas)')
    story.append(p('Pedir estes itens primeiro pois têm prazo longo de entrega:'))
    f1 = [
        ['Item',                          'O que buscar',                            'Preço est.'],
        ['Speeduino Shield v0.4.4c',      '"speeduino shield v0.4" — preferir montado','R$150–300'],
        ['Controlador Wideband CJ125',    '"cj125 wideband controller kit"',          'R$80–150'],
        ['Sender pressão de óleo',        '"oil pressure sender 0-10bar 0.5-4.5v"',   'R$35–60'],
        ['Sensor VSS Hall',               '"hall effect speed sensor motorcycle 5v"',  'R$20–35'],
        ['Conector AMP Superseal',        '"amp superseal 1.5 connector kit" — 4 kits','R$80–120'],
        ['Subtotal Fase 1',               '',                                          'R$365–665'],
    ]
    story.append(tabela(f1, [4.5*cm, 7.5*cm, 3*cm]))

    story.append(sp(6))
    story += h2('Fase 2 — Compra Local (esta semana)')
    f2 = [
        ['Item',                          'Onde comprar',                 'Preço est.'],
        ['Arduino Mega 2560 (clone)',      'Mercado Livre / FilipeFlop',  'R$60–90'],
        ['ESP32 DevKit 38 pinos',          'FilipeFlop / RoboCore',       'R$35–50'],
        ['Sonda Lambda LSU 4.9',          'Autopeças (igual ao VW Golf)', 'R$120–200'],
        ['Sensor Knock Bosch',            'Autopeças (igual ao Gol 1.0)','R$30–50'],
        ['Adaptador rosca óleo',          'Autopeças de motos',           'R$15–25'],
        ['BMP280 MAP sensor',             'AliExpress / ML',              'R$12–18'],
        ['Kit eletrônicos',               'Casa da Robótica / ML',        'R$50–60'],
        ['Subtotal Fase 2',               '',                             'R$322–493'],
    ]
    story.append(tabela(f2, [4.5*cm, 5.5*cm, 3*cm]))

    story.append(sp(6))
    story += h2('Fase 3 — Mecânica e Proteção (antes da montagem)')
    f3 = [
        ['Item',                      'Preço est.'],
        ['Fios automotivos + terminais','R$105'],
        ['Caixa estanque IP65',        'R$35–50'],
        ['Relés × 3 + fusíveis',       'R$43'],
        ['Manga termorretrátil + fita','R$25'],
        ['Espaçadores, calços silicone','R$15'],
        ['Subtotal Fase 3',            'R$223–238'],
    ]
    story.append(tabela(f3, [9*cm, 3*cm]))

    story.append(sp(6))
    story += h2('Versão Budget (~R$537 — motor já funciona)')
    story.append(p(
        'Para começar com o menor investimento possível, deixando melhorias para depois:'
    ))
    budget = [
        ['Item',                     'Versão econômica',                'Preço'],
        ['Speeduino',                'PCB nu JLCPCB + componentes',    'R$120'],
        ['Arduino Mega',             'Clone Mercado Livre',             'R$60'],
        ['ESP32',                    'WROOM-32 DevKit',                 'R$35'],
        ['MAP',                      'BMP280 I2C (vs MPX4250)',        'R$12'],
        ['Wideband',                 'LSU 4.9 usada ML + CJ125 novo',  'R$160'],
        ['Fios + relés + caixa',     'Autopeças local',                'R$150'],
        ['TOTAL MÍNIMO',             '',                               'R$537'],
    ]
    story.append(tabela(budget, [5*cm, 5.5*cm, 3*cm]))
    story.append(dica(
        'DICA: Knock, pressão de óleo e VSS são melhorias — o motor funciona sem eles. '
        'Adicione após a primeira partida e calibração.'
    ))

    # ── 10. NOTAS DE SEGURANÇA ────────────────────────────────────────────────
    story.append(PageBreak())
    story += h1('10. Notas de Segurança e Próximos Passos')

    story += h2('Checklist de Segurança — Antes da Primeira Partida')
    checks = [
        'Verificar resistência do injetor: esperado 12–16Ω (alta impedância)',
        'Verificar tipo do sensor CPS: VR indutivo (necessita conditioner) ou Hall effect',
        'Confirmar roda fônica 36-1 com osciloscópio antes de configurar trigger',
        'Testar pressão de combustível: 3,0 ± 0,2 bar com bomba ligada',
        'Verificar isolamento de todos os fios (sem curto com chassis)',
        'Confirmar estrela de terra única no bloco do motor',
        'Testar relé da bomba separadamente antes de ligar a ECU',
        'Medir tensão de saída do MAP/BMP280 antes de conectar',
        'Confirmar TPS: ~0,4V fechado, ~4,6V aberto',
        'Ter extintor próximo durante primeiras partidas',
    ]
    for c_item in checks:
        story.append(bul(f'☐ {c_item}'))

    story.append(sp(8))
    story += h2('Próximos Passos Recomendados')
    passos2 = [
        ('1. Diagnóstico primeiro',
         'Execute o MotoScan na ECU original para ler os códigos de falha antes de desmontar qualquer coisa.'),
        ('2. Compra Fase 1',
         'Faça o pedido no AliExpress (Speeduino shield, CJ125, Superseal). Prazo: 3–5 semanas.'),
        ('3. Compra Fase 2',
         'Arduino, ESP32, sonda LSU 4.9, sensor knock — tudo disponível localmente.'),
        ('4. Montagem em bancada',
         'Monte e configure o Speeduino no TunerStudio antes de instalar na moto. Simule o CPS com gerador de função.'),
        ('5. Firmware ESP32',
         'Compile com PlatformIO: cd firmware/esp32-ble-bridge && pio run --target upload'),
        ('6. App Flutter',
         'cd mobile-app && flutter pub get && flutter run. Testar comunicação BLE em bancada.'),
        ('7. Instalação na moto',
         'Substituir ECU original, refazer chicote com conectores Superseal, testar cada sensor.'),
        ('8. Primeira partida',
         'Seguir checklist da seção 7. Monitorar AFR wideband durante todo o aquecimento.'),
        ('9. Calibração em estrada',
         'Usar AutoTune do TunerStudio para ajustar VE table automaticamente com wideband.'),
    ]
    for titulo, desc in passos2:
        story += h3(titulo)
        story.append(p(desc))

    story.append(sp(8))
    story.append(aviso(
        'AVISO LEGAL: Este projeto envolve modificação no sistema de combustível e ignição '
        'de um veículo. Realize todos os testes em bancada antes da instalação. O autor não '
        'se responsabiliza por danos causados pelo uso inadequado do sistema.'
    ))

    story.append(sp(10))
    story += h2('Repositório do Projeto')
    story.append(p(
        'Todos os arquivos de firmware, app Flutter e documentação estão disponíveis em: '
        '<b>github.com/gustavowalkersgroup/bmwg650s</b>'
    ))
    story.append(p(
        'Branch de desenvolvimento: <b>claude/bmw-f650gs-efi-retrofit-EgTGE</b>'
    ))

    # ── Gera o PDF ────────────────────────────────────────────────────────────
    doc.build(
        story,
        onFirstPage=on_page,
        onLaterPages=on_page,
    )
    print(f'PDF gerado: {OUTPUT}')
    size_kb = os.path.getsize(OUTPUT) // 1024
    print(f'Tamanho: {size_kb} KB  |  {doc.page} páginas')


if __name__ == '__main__':
    build_pdf()
