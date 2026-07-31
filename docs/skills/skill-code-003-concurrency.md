---
id: SKILL-CODE-003
name: Concurrency & Distributed Systems
category: coding
phases: [3]
roles: [backend-engineer, architect, sre]
required_level: expert
agent_delegable: assisted
agent_trend: rising
related: [SKILL-ARCH-003, SKILL-CODE-004]
review_by: 2027-01-31
---

# Concurrency & Distributed Systems

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-003 — Data Modeling](skill-arch-003-data-modeling.md) · [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md)

## นิยาม
ความสามารถในการเขียนและตรวจสอบโค้ดที่ทำงานพร้อมกันหลายเส้นทาง หรือกระจายข้ามเครื่อง โดยเข้าใจว่าอะไรที่รับประกันไม่ได้บ้าง

## ทำไมสำคัญตอนนี้
เป็นพื้นที่ที่ agent พลาดบ่อยและพลาดแบบมองไม่เห็น — โค้ดที่มี race condition ผ่าน test ทุกครั้งในเครื่อง dev แล้วพังเฉพาะตอนมี load จริง ไม่มี static analysis ตัวไหนจับได้ครบ ทำให้ต้องพึ่งการตรวจสอบของมนุษย์ที่มีทักษะนี้เท่านั้น

## ระดับ
### Foundation
- เข้าใจความต่างระหว่าง concurrency กับ parallelism
- ใช้ primitive พื้นฐาน (mutex, channel, async/await) ได้ตามตัวอย่าง

### Proficient
- ระบุ critical section และเลือกกลไกป้องกันได้เหมาะสม
- เข้าใจ transaction isolation level และผลของแต่ละระดับ
- ออกแบบ retry ที่ปลอดภัย (idempotent + backoff + jitter)

### Expert
- วิเคราะห์ failure mode ของระบบกระจายได้ (partial failure, network partition, clock skew)
- ออกแบบ consistency model ที่เหมาะกับความต้องการจริง ไม่ใช่เลือก strong ทุกกรณี
- อ่านโค้ดแล้วเห็น race condition ที่ยังไม่เคยเกิด

## วิธีประเมิน
ให้โค้ดที่มี race condition ฝังอยู่ (เช่น check-then-act บนยอดคงเหลือ) แล้วให้หาภายใน 10 นาที
คำถามต่อ: "ถ้ามีสอง request มาพร้อมกัน จะเกิดอะไร และแก้อย่างไรโดยไม่ใช้ lock ทั้งตาราง"

## เส้นทางพัฒนา
1. สร้าง race condition ให้เกิดจริงในเครื่องด้วย load test — ต้องเห็นกับตาถึงจะเข้าใจ
2. ศึกษา isolation level ของ DB ที่ใช้ และทดลองแต่ละระดับ
3. อ่าน *Designing Data-Intensive Applications* บทที่ 7–9
4. ฝึกเขียน property test ที่รันโค้ดเดียวกันแบบขนานแล้วตรวจ invariant

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียนโค้ด async ตามรูปแบบมาตรฐาน, ใส่ retry/backoff, แปลง sync เป็น async
- **Agent ทำแทนไม่ได้:** ตรวจว่าโค้ดที่มันเขียนปลอดภัยภายใต้ concurrency — ต้องมีมนุษย์ที่มีทักษะนี้อ่านทุกครั้งสำหรับงาน Tier C

## สัญญาณว่าทีมขาดทักษะนี้
- Bug ที่ "เกิดบ้างไม่เกิดบ้าง" และปิดด้วยการ retry
- ไม่มีใครตอบได้ว่าใช้ isolation level อะไรอยู่
