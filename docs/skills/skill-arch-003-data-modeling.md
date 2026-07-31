---
id: SKILL-ARCH-003
name: Data Modeling
category: architecture
phases: [1, 2]
roles: [architect, backend-engineer, data-engineer]
required_level: expert
agent_delegable: assisted
agent_trend: rising
related: [SKILL-SPEC-002, SKILL-BLD-004]
review_by: 2027-01-31
---

# Data Modeling

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-SPEC-002 — Invariant Identification](skill-spec-002-invariant-identification.md) · [SKILL-BLD-004 — Database Operations](skill-bld-004-database-operations.md)

## นิยาม
ความสามารถในการออกแบบโครงสร้างข้อมูลที่สะท้อนกฎของ domain จริง และบังคับความถูกต้องที่ระดับ schema ไม่ใช่ที่ระดับโค้ด

## ทำไมสำคัญตอนนี้
โค้ดผิดแก้ได้ ข้อมูลผิดกู้ไม่ได้ — และ agent เขียนโค้ดที่ข้าม validation ได้ง่ายมาก (`update_column`, `insert_all`, raw SQL) constraint ที่ระดับฐานข้อมูลจึงกลายเป็นแนวป้องกันสุดท้ายที่แท้จริง

## ระดับ
### Foundation
- ออกแบบตารางจาก entity ที่ชัดเจนได้
- ใช้ foreign key และ index พื้นฐานเป็น

### Proficient
- normalize/denormalize อย่างมีเหตุผล ไม่ใช่ตามสูตร
- ใส่ constraint (unique, check, not null) ที่สะท้อนกฎธุรกิจ
- ออกแบบให้รองรับการเปลี่ยนแปลงโดยไม่ต้อง migration ใหญ่ทุกครั้ง

### Expert
- ออกแบบ state machine ที่บังคับได้ที่ระดับข้อมูล
- จัดการกับ temporal data, soft delete, audit trail อย่างถูกต้อง
- คาดการณ์ปัญหา performance จากรูปแบบ query ก่อนที่จะเกิด

## วิธีประเมิน
ให้ requirement: "order ยกเลิกได้เฉพาะตอนที่ยังไม่ถูก capture" แล้วถามว่าจะบังคับกฎนี้อย่างไร
- ตอบว่า "validate ใน service layer" = Foundation
- ตอบว่า "check constraint + state column + unique index บน idempotency key" = Proficient ขึ้นไป
- อธิบายได้ว่าถ้ามี concurrent request สองอันจะเกิดอะไร = Expert

## เส้นทางพัฒนา
1. หยิบ business rule ในระบบปัจจุบัน 5 ข้อ แล้วดูว่ามีกี่ข้อที่บังคับที่ DB จริง
2. ฝึกเขียน check constraint และ partial unique index
3. ศึกษา isolation level และทดลองสร้าง race condition ให้เกิดจริงในเครื่อง
4. อ่าน *Designing Data-Intensive Applications* บทที่เกี่ยวกับ transaction

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน migration จาก schema ที่ออกแบบแล้ว, เสนอ index จาก query pattern, ตรวจ schema กับ model ให้ตรงกัน
- **Agent ทำแทนไม่ได้:** ตัดสินว่ากฎธุรกิจข้อไหนต้องเป็น constraint, ประเมินผลกระทบของ schema change ต่อข้อมูลที่มีอยู่

## สัญญาณว่าทีมขาดทักษะนี้
- ข้อมูลในฐานข้อมูลมี state ที่ "เป็นไปไม่ได้" ตามกฎธุรกิจ
- validation อยู่แต่ในโค้ด ไม่มีที่ schema เลย
- ต้องเขียน script ซ่อมข้อมูลเป็นประจำ
