---
id: SKILL-TEST-004
name: Contract Testing
category: testing
phases: [1, 4]
roles: [qa, sdet, backend-engineer, architect]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-CODE-002, SKILL-ARCH-002]
review_by: 2027-01-31
---

# Contract Testing

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-002 — API Design](skill-code-002-api-design.md) · [SKILL-ARCH-002 — Boundary & Module Design](skill-arch-002-boundary-design.md)

## นิยาม
ความสามารถในการนิยามและบังคับข้อตกลงระหว่างสองระบบ ให้ทั้งฝั่งผู้ให้และผู้ใช้บริการทดสอบกันได้โดยไม่ต้องรันพร้อมกัน

## ทำไมสำคัญตอนนี้
เมื่อ agent เปลี่ยนโค้ดหลายจุดพร้อมกันเร็วขึ้น การเปลี่ยนที่ทำลาย consumer จะเกิดบ่อยขึ้นตาม contract test คือ gate ที่จับได้ตั้งแต่ CI แทนที่จะจับได้ตอน integration environment หรือแย่กว่านั้นคือตอน production

## ระดับ
### Foundation
- เข้าใจว่า contract test ต่างจาก integration test อย่างไร
- รัน contract test ที่มีอยู่ได้

### Proficient
- เขียน contract จากฝั่ง consumer และให้ provider verify ได้
- ใช้เครื่องมือ (Pact, rswag, OpenAPI validator) ในการ CI
- จัดการ contract versioning เมื่อมีหลาย consumer

### Expert
- ออกแบบ contract ที่ยืดหยุ่นพอไม่ให้เปราะ แต่เข้มพอที่จะมีประโยชน์
- จัดการ contract ข้ามทีมและข้ามองค์กร
- ใช้ contract เป็นเครื่องมือออกแบบ ไม่ใช่แค่เครื่องมือทดสอบ

## วิธีประเมิน
ถาม: "ถ้าเราเพิ่ม field ใหม่ใน response จะทำให้ consumer พังไหม แล้วถ้าเปลี่ยนชนิดของ field เดิมล่ะ"
คำตอบควรแยกได้ว่าอะไรคือ backward compatible อะไรไม่ใช่ และ contract test ควรจับอันไหน

## เส้นทางพัฒนา
1. ตั้ง contract test ระหว่างสอง service ที่คุยกันบ่อยที่สุดก่อน
2. ฝึกเขียน OpenAPI spec ก่อน implementation แล้ว generate test จากมัน
3. ทดลองทำ breaking change แล้วดูว่า contract test จับได้ไหม
4. ศึกษาความต่างระหว่าง consumer-driven กับ provider-driven contract

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน contract test จาก spec, generate จาก OpenAPI, ตรวจ compatibility ระหว่างเวอร์ชัน
- **Agent ทำแทนไม่ได้:** ตัดสินว่าอะไรควรอยู่ใน contract และอะไรควรเป็นรายละเอียดภายในที่เปลี่ยนได้อิสระ

## สัญญาณว่าทีมขาดทักษะนี้
- Integration พังตอน deploy บ่อย
- ต้อง deploy หลาย service พร้อมกันเสมอ
- ไม่มีใครรู้ว่าใครใช้ endpoint ไหนอยู่บ้าง
