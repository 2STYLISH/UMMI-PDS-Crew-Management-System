import os
from fpdf import FPDF
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = os.path.join(os.path.dirname(__file__), 'ai-fixtures')
os.makedirs(OUT_DIR, exist_ok=True)

# 1. Manifest Resume (Native text PDF)
def create_manifest_resume():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 16)
    pdf.cell(0, 10, "SEAFARER CURRICULUM VITAE", ln=True, align="C")
    pdf.ln(5)

    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, "I. PERSONAL INFORMATION", ln=True)
    pdf.set_font("Helvetica", size=10)
    pdf.cell(0, 6, "Surname / Last Name: Dela Cruz", ln=True)
    pdf.cell(0, 6, "Given / First Name: Roberto", ln=True)
    pdf.cell(0, 6, "Middle Name: Alvarez", ln=True)
    pdf.cell(0, 6, "Date of Birth: 1985-04-12", ln=True)
    pdf.cell(0, 6, "Place of Birth: Manila", ln=True)
    pdf.cell(0, 6, "Gender: Male", ln=True)
    pdf.cell(0, 6, "Civil Status: Married", ln=True)
    pdf.cell(0, 6, "Contact Number: 0917-555-0199", ln=True)
    pdf.cell(0, 6, "Email Address: roberto.delacruz@synthetic-qa.com", ln=True)
    pdf.cell(0, 6, "Nationality: Filipino", ln=True)
    pdf.cell(0, 6, "Applied Rank / Position: Chief Cook", ln=True)
    pdf.ln(5)

    pdf.set_font("Helvetica", "B", 12)
    pdf.cell(0, 8, "II. NOTE ON UNSTATED FIELDS", ln=True)
    pdf.set_font("Helvetica", size=10)
    pdf.cell(0, 6, "Blood type, religion, height, and weight are intentionally omitted.", ln=True)

    out_path = os.path.join(OUT_DIR, 'synthetic_manifest_resume.pdf')
    pdf.output(out_path)
    print(f"Created: {out_path}")

# 2. Conflicting Document 1 (Doc A: Birth Date 1985-04-12)
def create_conflict_doc1():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "SEAMAN DISCHARGE BOOK - PAGE 1", ln=True, align="C")
    pdf.set_font("Helvetica", size=10)
    pdf.cell(0, 6, "Full Name: Roberto Alvarez Dela Cruz", ln=True)
    pdf.cell(0, 6, "Date of Birth: 1985-04-12", ln=True)
    pdf.cell(0, 6, "Place of Birth: Manila", ln=True)
    out_path = os.path.join(OUT_DIR, 'synthetic_conflict_doc1.pdf')
    pdf.output(out_path)
    print(f"Created: {out_path}")

# 3. Conflicting Document 2 (Doc B: Birth Date 1985-04-15 - Conflicting!)
def create_conflict_doc2():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "TRAINING CERTIFICATE - PAGE 1", ln=True, align="C")
    pdf.set_font("Helvetica", size=10)
    pdf.cell(0, 6, "Full Name: Roberto Alvarez Dela Cruz", ln=True)
    pdf.cell(0, 6, "Date of Birth: 1985-04-15", ln=True)
    pdf.cell(0, 6, "Place of Birth: Quezon City", ln=True)
    out_path = os.path.join(OUT_DIR, 'synthetic_conflict_doc2.pdf')
    pdf.output(out_path)
    print(f"Created: {out_path}")

# 4. Unmatched Reference Value Document
def create_unmatched_rank_doc():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "CERTIFICATE OF ENDORSEMENT", ln=True, align="C")
    pdf.set_font("Helvetica", size=10)
    pdf.cell(0, 6, "Seafarer Name: Roberto Dela Cruz", ln=True)
    pdf.cell(0, 6, "Position / Rank Endorsed: Deep Sea Starship Operations Specialist", ln=True)
    pdf.cell(0, 6, "Certificate No: END-2024-X99", ln=True)
    out_path = os.path.join(OUT_DIR, 'synthetic_unmatched_rank.pdf')
    pdf.output(out_path)
    print(f"Created: {out_path}")

# 5. Scanned Document (Pure raster image inside PDF, 0 text letters)
def create_scanned_pdf():
    img = Image.new("RGB", (800, 1000), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)
    draw.text((50, 50), "OFFICIAL GOVERNMENT SEAFARER ID (SCANNED COPY)", fill=(0, 0, 0))
    draw.text((50, 100), "Last Name: Dela Cruz", fill=(0, 0, 0))
    draw.text((50, 140), "First Name: Roberto", fill=(0, 0, 0))
    draw.text((50, 180), "Date of Birth: 1985-04-12", fill=(0, 0, 0))
    draw.text((50, 220), "Rank: Chief Cook", fill=(0, 0, 0))

    img_path = os.path.join(OUT_DIR, 'scanned_temp.png')
    img.save(img_path)

    pdf = FPDF()
    pdf.add_page()
    pdf.image(img_path, x=10, y=10, w=190)
    out_path = os.path.join(OUT_DIR, 'synthetic_scanned_doc.pdf')
    pdf.output(out_path)
    if os.path.exists(img_path):
        os.remove(img_path)
    print(f"Created: {out_path}")

# 6. Repeating Records with Duplicate
def create_repeating_records_doc():
    pdf = FPDF()
    pdf.add_page()
    pdf.set_font("Helvetica", "B", 14)
    pdf.cell(0, 10, "RECORD OF SEA SERVICE & CERTIFICATES", ln=True, align="C")
    pdf.ln(5)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 6, "Sea Service History:", ln=True)
    pdf.set_font("Helvetica", size=9)
    pdf.cell(0, 5, "1. Vessel: MV Pacific Trader | Rank: Cook | Joined: 2021-01-10 | Discharged: 2021-10-15", ln=True)
    pdf.cell(0, 5, "2. Vessel: MV Pacific Trader | Rank: Cook | Joined: 2021-01-10 | Discharged: 2021-10-15", ln=True) # Duplicate
    pdf.cell(0, 5, "3. Vessel: MV Atlantic Carrier | Rank: Chief Cook | Joined: 2022-03-01 | Discharged: 2022-12-05", ln=True)
    pdf.ln(4)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 6, "Certificates & Training:", ln=True)
    pdf.set_font("Helvetica", size=9)
    pdf.cell(0, 5, "1. Basic Safety Training (BST) | Number: BST-2020-9981 | Issued: 2020-01-15", ln=True)
    pdf.cell(0, 5, "2. Basic Safety Training (BST) | Number: BST-2020-9981 | Issued: 2020-01-15", ln=True) # Duplicate
    pdf.cell(0, 5, "3. Shipboard Culinary Management | Number: SCM-2021-4412 | Issued: 2021-02-20", ln=True)

    out_path = os.path.join(OUT_DIR, 'synthetic_repeating_records.pdf')
    pdf.output(out_path)
    print(f"Created: {out_path}")

if __name__ == '__main__':
    create_manifest_resume()
    create_conflict_doc1()
    create_conflict_doc2()
    create_unmatched_rank_doc()
    create_scanned_pdf()
    create_repeating_records_doc()
