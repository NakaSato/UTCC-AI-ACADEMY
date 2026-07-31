---
id: SKILL-SPEC-001
name: Spec Writing
category: specification
phases: [2]
roles: [spec-owner, product-owner, tech-lead, qa]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-SPEC-002, SKILL-SPEC-003, SKILL-TEST-001]
review_by: 2027-01-31
---

# Spec Writing

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-SPEC-003 — Ambiguity Detection](skill-spec-003-ambiguity-detection.md) · [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md)

## นิยาม
ความสามารถในการแปลงความต้องการที่เขียนด้วยคำคุณศัพท์ ("ง่าย", "เร็ว", "เชื่อถือได้") ให้เป็นข้อความที่ **เครื่องตรวจสอบได้** และไม่เหลือช่องให้ตีความสองทาง

## ทำไมสำคัญตอนนี้
นี่คือทักษะที่ให้ผลตอบแทนสูงที่สุดในทั้งคลัง เพราะคุณค่าของ agent แปรผันตรงกับคุณภาพของ spec — agent ที่เก่งที่สุดที่ได้รับ spec คลุมเครือ จะผลิตของที่ผิดได้เร็วกว่าเดิมเท่านั้นเอง การลงทุนที่นี่ให้ผลมากกว่าลงทุนที่ agent tooling หลายเท่า

## ระดับ
### Foundation
- เขียน user story ตาม template ได้
- แยก acceptance criteria ออกจากคำอธิบายทั่วไป

### Proficient
- เขียน AC ที่ชี้ไปยัง test file ที่มีอยู่จริงได้ทุกข้อ
- ระบุ non-goal ชัดเจน (สิ่งที่จงใจไม่ทำ)
- ระบุ rollback plan และ observability ที่ต้องมี

### Expert
- เขียน spec ที่คนอื่นอ่านแล้วทำได้โดยไม่ต้องถามกลับเลย
- เขียน invariant ที่จับ bug ที่ตัวอย่างทดสอบจับไม่ได้
- รู้ว่าเมื่อไหร่ควรเขียน spec ละเอียด และเมื่อไหร่การเขียนละเอียดคือการเสียเวลา

## วิธีประเมิน
ให้ requirement ที่คลุมเครือ เช่น "ผู้ใช้ควรยกเลิกคำสั่งซื้อได้ง่าย" แล้วให้เขียนเป็น spec ภายใน 20 นาที
เกณฑ์ผ่าน:
- ทุก AC ระบุ verified-by ที่เป็นไฟล์ test
- มี non-goal อย่างน้อยหนึ่งข้อ
- มี invariant ที่ไม่ใช่แค่ทวน AC
- มี rollback plan

จากนั้นเอา spec นั้นให้ agent implement แล้วดูว่ามันติดคำถามกี่ข้อ — ยิ่งน้อยยิ่งแสดงว่า spec ดี

## เส้นทางพัฒนา
1. หยิบ requirement เก่าที่เคยเข้าใจผิดกันในทีม เขียนใหม่ให้มี invariant + AC ที่ชี้ไป test ทำซ้ำ 10 ครั้ง
2. ก่อนเขียนโค้ดทุกครั้ง ให้ agent อ่าน spec แล้วถามว่า "มีอะไรที่ยังไม่ตอบ" — คำถามที่มันถามคือรูรั่วของคุณ
3. ฝึกเขียน non-goal ให้ได้อย่างน้อยหนึ่งข้อเสมอ
4. อ่าน spec ของ RFC หรือ standard จริง (เช่น RFC ของ HTTP) สังเกตวิธีใช้ MUST/SHOULD/MAY

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ร่าง spec จาก PRD, สร้าง test skeleton จาก AC, **ชี้ช่องว่างที่ spec ยังไม่ตอบ (มีค่าที่สุด)**
- **Agent ทำแทนไม่ได้:** นิยาม invariant, ตัดสินว่าอะไรอยู่ใน scope, รับผิดชอบเมื่อ spec ผิด

## สัญญาณว่าทีมขาดทักษะนี้
- Agent block rate ต่ำผิดปกติ (แปลว่ามันกำลังเดา ไม่ใช่ว่า spec ดี)
- Rework rate สูงกว่า 25%
- คำถามระหว่าง implement มีเยอะ และเป็นคำถามที่ควรตอบได้ตั้งแต่ต้น
