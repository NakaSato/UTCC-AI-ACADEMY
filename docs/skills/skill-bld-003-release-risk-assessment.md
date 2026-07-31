---
id: SKILL-BLD-003
name: Release Risk Assessment
category: build
phases: [6]
roles: [tech-lead, sre, release-manager, product-owner]
required_level: expert
agent_delegable: false
agent_trend: rising
related: [SKILL-BLD-004, SKILL-OPS-002]
review_by: 2027-01-31
---

# Release Risk Assessment

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-BLD-004 — Database Operations](skill-bld-004-database-operations.md) · [SKILL-OPS-002 — Incident Response](skill-ops-002-incident-response.md)

## นิยาม
ความสามารถในการประเมินก่อน deploy ว่าอะไรอาจพัง พังแล้วกระทบใครแค่ไหน จะรู้ได้เร็วแค่ไหน และถอยกลับได้จริงหรือไม่

## ทำไมสำคัญตอนนี้
เมื่อจำนวนการเปลี่ยนแปลงต่อ release สูงขึ้นมาก การอ่าน diff ทั้งหมดก่อนปล่อยกลายเป็นไปไม่ได้ ทักษะนี้จึงเปลี่ยนจาก "อ่านให้ครบ" เป็น "รู้ว่าต้องอ่านตรงไหน" และ Change Failure Rate กลายเป็นตัวชี้วัดที่สำคัญที่สุดในชุด DORA

## ระดับ
### Foundation
- ทำตาม release checklist ที่มีอยู่
- รู้ว่าต้องแจ้งใครก่อน deploy

### Proficient
- ระบุได้ว่าการเปลี่ยนแปลงไหนใน release นี้เสี่ยงที่สุดและเพราะอะไร
- ตรวจสอบว่า rollback plan ใช้ได้จริง ไม่ใช่แค่เขียนไว้
- กำหนดเกณฑ์ verify หลัง deploy ที่ชัดเจน

### Expert
- ประเมินความเสี่ยงจากปฏิสัมพันธ์ระหว่างการเปลี่ยนแปลงหลายชิ้น ไม่ใช่ทีละชิ้น
- ตัดสินใจได้ว่าเมื่อไหร่ควรแยก release และเมื่อไหร่รวมได้
- รู้ว่าความเสี่ยงข้อไหนควรยอมรับ

## วิธีประเมิน
ให้ release ที่มี 12 PR รวม migration หนึ่งตัวและการเปลี่ยน config หนึ่งจุด ถามว่า:
1. ตัวไหนเสี่ยงที่สุด เพราะอะไร
2. ถ้าพัง จะรู้ภายในกี่นาที และรู้ได้จากอะไร
3. rollback ตัวไหนที่ทำไม่ได้จริง

คนที่ไม่ระบุว่า migration rollback ไม่ได้ = ยังไม่ถึง Proficient

## เส้นทางพัฒนา
1. ทำ pre-mortem ก่อน release ใหญ่: สมมติว่าพังแล้ว มาจากอะไรได้บ้าง
2. ทดสอบ rollback จริงในสภาพแวดล้อม staging อย่างน้อยไตรมาสละครั้ง
3. ทบทวน incident ที่เกิดจาก release ย้อนหลัง — สัญญาณอะไรที่มองข้ามไป
4. ฝึกเขียน release doc ที่มี verify criteria เป็นตัวเลข ไม่ใช่ "ดูว่าปกติไหม"

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** สรุปการเปลี่ยนแปลงใน release, สร้าง changelog, ตรวจว่ามี migration หรือ config change ไหม
- **Agent ทำแทนไม่ได้:** ตัดสินว่าปล่อยหรือไม่ปล่อย — เป็นการรับความเสี่ยงซึ่งต้องมีมนุษย์รับผิดชอบ

## สัญญาณว่าทีมขาดทักษะนี้
- Change Failure Rate สูงกว่า 15%
- rollback plan เขียนว่า "revert commit" กับ release ที่มี migration
- ไม่มีเกณฑ์ verify หลัง deploy ที่เป็นตัวเลข
