---
id: SKILL-PROD-003
name: User Research
category: product
phases: [0]
roles: [product-owner, ux-designer, business-analyst]
required_level: proficient
agent_delegable: assisted
agent_trend: stable
related: [SKILL-PROD-001]
review_by: 2027-01-31
---

# User Research

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-PROD-001 — Problem Framing](skill-prod-001-problem-framing.md)

## นิยาม
ความสามารถในการได้มาซึ่งข้อมูลจากผู้ใช้จริงโดยไม่ใส่คำตอบเข้าไปในคำถาม และแยกได้ว่าอะไรคือสิ่งที่ผู้ใช้ **ทำ** กับสิ่งที่ผู้ใช้ **บอกว่าทำ**

## ทำไมสำคัญตอนนี้
คงเดิม — agent ช่วยประมวลผลข้อมูลได้มาก แต่การได้มาซึ่งข้อมูลที่ไม่ปนเปื้อนยังเป็นงานมนุษย์ทั้งหมด และเป็นวัตถุดิบตั้งต้นของทั้งสายโซ่

## ระดับ
### Foundation
- ทำ interview ตาม script ที่คนอื่นเตรียมได้
- จดบันทึกโดยไม่ตีความไปพร้อมกัน

### Proficient
- ตั้งคำถามปลายเปิดที่ไม่ชี้นำ
- ถามถึงพฤติกรรมในอดีตแทนที่จะถามความตั้งใจในอนาคต
- แยกข้อสังเกตออกจากข้อสรุปในบันทึก

### Expert
- ออกแบบ research ที่ตอบคำถามที่ตัดสินใจได้จริง ไม่ใช่แค่ได้ข้อมูลเพิ่ม
- รู้ว่าเมื่อไหร่ข้อมูลพอแล้ว (saturation)
- จับได้ว่าตัวเองกำลังหาหลักฐานมายืนยันสิ่งที่เชื่ออยู่แล้ว

## วิธีประเมิน
ให้เขาเขียนคำถามสัมภาษณ์ 5 ข้อสำหรับฟีเจอร์ที่กำลังคิดจะทำ แล้วนับว่า:
- มีกี่ข้อที่ชี้นำ ("คุณคิดว่าฟีเจอร์นี้จะช่วยไหม")
- มีกี่ข้อที่ถามอนาคต ("คุณจะใช้ไหม") แทนที่จะถามอดีต ("ครั้งล่าสุดที่เจอปัญหานี้คือเมื่อไหร่ แล้วทำยังไง")

เกิน 2 ข้อชี้นำ = ยังไม่ถึง Proficient

## เส้นทางพัฒนา
1. อ่าน *The Mom Test* (Rob Fitzpatrick) — สั้นและเปลี่ยนวิธีถามได้ทันที
2. อัดเสียง interview ของตัวเองแล้วฟังย้อน นับจำนวนครั้งที่พูดแทรกหรือชี้นำ
3. ทำ 5 interview ติดกันโดยห้ามพูดถึงทางแก้ที่คิดไว้เลย
4. เทียบสิ่งที่ผู้ใช้บอกกับ analytics จริง ดูว่าตรงกันแค่ไหน

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ถอดเทป, จัดกลุ่ม theme พร้อม quote อ้างอิง, สรุปความถี่ของ pain point
- **Agent ทำแทนไม่ได้:** ทำ interview เอง, อ่านภาษากาย, ตัดสินว่าผู้ใช้พูดจริงหรือพูดให้เราพอใจ

## สัญญาณว่าทีมขาดทักษะนี้
- ข้อสรุปจาก research ตรงกับสิ่งที่ทีมเชื่ออยู่แล้วทุกครั้ง
- อ้าง "ผู้ใช้ต้องการ X" โดยไม่มีใครระบุได้ว่าผู้ใช้คนไหนพูดเมื่อไหร่
