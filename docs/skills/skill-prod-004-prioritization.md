---
id: SKILL-PROD-004
name: Prioritization
category: product
phases: [0]
roles: [product-owner, engineering-manager]
required_level: expert
agent_delegable: false
agent_trend: rising
related: [SKILL-PROD-001, SKILL-BLD-003]
review_by: 2027-01-31
---

# Prioritization

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-PROD-001 — Problem Framing](skill-prod-001-problem-framing.md) · [SKILL-BLD-003 — Release Risk Assessment](skill-bld-003-release-risk-assessment.md)

## นิยาม
ความสามารถในการเลือกว่า **จะไม่ทำอะไร** และอธิบายเหตุผลให้ผู้มีส่วนได้ส่วนเสียยอมรับได้ โดยตัดสินบนข้อมูลที่ไม่ครบเสมอ

## ทำไมสำคัญตอนนี้
เมื่อ capacity ในการสร้างเพิ่มขึ้นหลายเท่า แรงกดดันให้ "ทำทุกอย่างเพราะทำได้แล้ว" จะสูงมาก ทักษะนี้เปลี่ยนจากการจัดคิวงาน เป็นการปกป้องโฟกัสของทีม

## ระดับ
### Foundation
- เรียงลำดับงานตามเกณฑ์ที่คนอื่นกำหนดให้ได้

### Proficient
- ใช้กรอบเช่น RICE / Cost of Delay ได้อย่างเข้าใจข้อจำกัดของมัน
- ระบุ opportunity cost ของแต่ละตัวเลือกได้
- ปฏิเสธงานได้พร้อมเหตุผลที่อ้างอิงเป้าหมาย

### Expert
- ตัดสินใจได้ในสถานการณ์ที่ข้อมูลขัดแย้งกันและมีการเมืองเข้ามาเกี่ยว
- กล้าหยุดโครงการที่ลงทุนไปแล้วมาก (ต้านทาน sunk cost)
- จัดลำดับโดยคำนึงถึงลำดับที่ทำให้เรียนรู้เร็วที่สุด ไม่ใช่แค่คุณค่าสูงสุด

## วิธีประเมิน
ให้ backlog 10 ชิ้นที่มีทั้งงานจากลูกค้ารายใหญ่ งานลดหนี้เทคนิค และงานที่ CEO ขอ แล้วให้เขาเลือก 3 ชิ้นสำหรับไตรมาสหน้า พร้อมอธิบายว่าจะบอกเจ้าของงานที่ถูกตัดออกว่าอย่างไร

ดูที่คำอธิบาย ไม่ใช่ที่ตัวเลือก — คนระดับ Expert จะพูดถึง opportunity cost และผลต่อเป้าหมายรวม ไม่ใช่แค่ "อันนี้ impact สูงกว่า"

## เส้นทางพัฒนา
1. ทุกครั้งที่รับงานใหม่เข้า sprint ให้ระบุว่างานอะไรถูกเลื่อนออกไปแทน — ฝึกให้ opportunity cost เป็นสิ่งที่มองเห็น
2. ฝึกเขียนคำปฏิเสธที่อ้างอิงเป้าหมายรวม ไม่ใช่อ้าง capacity
3. ทบทวนย้อนหลังทุกไตรมาส: ถ้าย้อนเวลาได้จะเลือกต่างไหม เพราะอะไร
4. ฝึกหยุดโครงการเล็กๆ ที่ไม่ไปไหนหนึ่งตัวต่อไตรมาส

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** คำนวณคะแนนตามกรอบที่ให้, สรุปผลกระทบของแต่ละตัวเลือก, หาข้อมูลประกอบ
- **Agent ทำแทนไม่ได้:** รับผิดชอบผลของการเลือก, อ่านการเมืองในองค์กร, ตัดสินใจภายใต้ความไม่แน่นอน

## สัญญาณว่าทีมขาดทักษะนี้
- ทุกอย่างเป็น P1
- Sprint เต็มตลอดแต่ไม่มีอะไรเสร็จสมบูรณ์
- ไม่มีใครจำได้ว่าปีที่แล้วตัดสินใจไม่ทำอะไรบ้าง
