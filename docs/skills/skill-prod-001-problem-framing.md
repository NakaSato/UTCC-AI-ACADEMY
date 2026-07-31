---
id: SKILL-PROD-001
name: Problem Framing
category: product
phases: [0]
roles: [product-owner, business-analyst, ux-designer]
required_level: expert
agent_delegable: false
agent_trend: rising
related: [SKILL-PROD-004, SKILL-SPEC-003]
review_by: 2027-01-31
---

# Problem Framing

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-PROD-004 — Prioritization](skill-prod-004-prioritization.md) · [SKILL-SPEC-003 — Ambiguity Detection](skill-spec-003-ambiguity-detection.md)

## นิยาม
ความสามารถในการแปลงคำขอที่มาในรูป **solution** ให้กลับไปเป็น **problem** ที่วัดได้ และระบุได้ว่าใครเดือดร้อน เดือดร้อนแค่ไหน และรู้ได้อย่างไรว่าแก้แล้ว

## ทำไมสำคัญตอนนี้
เมื่อการสร้างของถูกลงมาก ความเสี่ยงย้ายจาก "สร้างไม่เสร็จ" ไปเป็น "สร้างของที่ไม่มีใครต้องการได้เร็วมาก" ทักษะนี้คือด่านแรกที่กันไม่ให้ทั้งสายโซ่วิ่งไปผิดทาง

## ระดับ
### Foundation
- แยกออกว่าอะไรคือ problem อะไรคือ solution เมื่อมีคนชี้ให้ดู
- ถามคำถาม "ทำไม" ต่อได้ 1–2 ชั้น

### Proficient
- แปลงคำขอเป็น problem statement ได้เองโดยไม่ต้องมีคนเตือน
- หา baseline ปัจจุบันได้ก่อนเสนอทางแก้
- ระบุ non-goal ได้ชัด

### Expert
- ท้าทายคำขอจากผู้มีอำนาจได้อย่างสร้างสรรค์โดยไม่เสียความสัมพันธ์
- มองเห็นว่าปัญหาที่ถูกเสนอมาเป็นอาการของปัญหาที่ลึกกว่า
- ตัดสินใจได้ว่าปัญหาไหน **ไม่ควรแก้**

## วิธีประเมิน
ให้คำขอจริงที่เคยได้รับ เช่น "อยากได้ dashboard สรุปยอดขาย" แล้วดูว่าเขา:
1. ถามว่าใครจะใช้ ใช้ตัดสินใจอะไร — หรือเริ่มออกแบบ dashboard ทันที
2. ถามว่าตอนนี้ตัดสินใจเรื่องนั้นด้วยอะไร แล้วมันพลาดตรงไหน
3. เสนอทางแก้ที่ไม่ใช่ dashboard ได้อย่างน้อยหนึ่งทาง

คนที่ข้ามข้อ 1–2 ไปเลย = ยังไม่ถึง Proficient

## เส้นทางพัฒนา
1. ฝึก "5 Whys" กับ requirement ที่เข้ามาทุกชิ้นเป็นเวลาหนึ่งเดือน
2. ก่อนเริ่มงานทุกชิ้น เขียนสามบรรทัด: ใครเดือดร้อน / ตอนนี้เขาทำยังไง / รู้ได้ยังไงว่าดีขึ้น
3. อ่าน *Continuous Discovery Habits* (Teresa Torres) — โดยเฉพาะ opportunity solution tree
4. ทบทวนย้อนหลัง: ฟีเจอร์ที่ทีมทำไปปีที่แล้ว มีกี่ตัวที่แก้ปัญหาจริง

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** สรุป interview, จัดกลุ่ม pain point พร้อมอ้างอิง, ค้นว่าคู่แข่งแก้ปัญหานี้อย่างไร
- **Agent ทำแทนไม่ได้:** ตัดสินว่าปัญหาไหนสำคัญ, ท้าทายผู้มีอำนาจ, รับผลของการเลือกผิด

## สัญญาณว่าทีมขาดทักษะนี้
- Backlog เต็มไปด้วยชื่อฟีเจอร์ ไม่มีปัญหาสักข้อ
- ตอบไม่ได้ว่าฟีเจอร์ที่ปล่อยไปเมื่อไตรมาสที่แล้วช่วยอะไร
- ทุก requirement เริ่มด้วย "อยากได้..." ไม่เคยเริ่มด้วย "ตอนนี้มีปัญหาว่า..."
