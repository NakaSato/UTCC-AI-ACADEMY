---
id: SKILL-OPS-002
name: Incident Response
category: operations
phases: [7]
roles: [sre, on-call, tech-lead, engineering-manager]
required_level: expert
agent_delegable: false
agent_trend: rising-critical
related: [SKILL-OPS-003, SKILL-CODE-004, SKILL-HUM-001]
review_by: 2027-01-31
---

# Incident Response

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-OPS-003 — Root Cause Analysis](skill-ops-003-root-cause-analysis.md) · [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md) · [SKILL-HUM-001 — Written Communication](skill-hum-001-written-communication.md)

## นิยาม
ความสามารถในการนำการแก้ปัญหาในสถานการณ์ที่ระบบกำลังเสียหาย ข้อมูลไม่ครบ มีหลายคนเกี่ยวข้อง และทุกนาทีมีต้นทุน

## ทำไมสำคัญตอนนี้
Throughput ที่สูงขึ้นแปลว่าจำนวน incident มีแนวโน้มสูงขึ้นตาม และเมื่อทีมเข้าใจโค้ดที่ตัวเองดูแลน้อยลง ความสามารถในการรับมือเหตุจึงกลายเป็นตัวแยกทีมที่รอดออกจากทีมที่ล่ม

## ระดับ
### Foundation
- ทำตาม runbook ได้
- รู้ว่าต้อง escalate เมื่อไหร่และหาใคร

### Proficient
- ทำหน้าที่ Incident Commander ได้ — แยกบทบาท สื่อสาร ตัดสินใจ
- แยก "บรรเทาอาการ" ออกจาก "แก้สาเหตุ" และเลือกทำอย่างแรกก่อนเสมอ
- สื่อสารกับผู้มีส่วนได้ส่วนเสียระหว่างเหตุอย่างสม่ำเสมอ

### Expert
- ตัดสินใจภายใต้ข้อมูลไม่ครบและความกดดันสูงได้อย่างมีสติ
- รู้ว่าเมื่อไหร่ควรหยุดหาสาเหตุแล้ว rollback ทันที
- จัดการทั้งด้านเทคนิคและด้านคนพร้อมกัน (คนที่ตื่นตระหนก คนที่โทษตัวเอง ผู้บริหารที่กดดัน)

## วิธีประเมิน
Game day: จงใจสร้างเหตุในระบบทดสอบ แล้วสังเกตว่าเขา
1. ประกาศบทบาทตัวเองชัดเจนไหม
2. บรรเทาก่อนหรือไล่หาสาเหตุก่อน
3. สื่อสารสถานะทุกกี่นาที
4. บันทึก timeline ระหว่างทางไหม

## เส้นทางพัฒนา
1. เข้าเวร on-call แบบมีพี่เลี้ยงก่อนรับผิดชอบเอง
2. ทำ game day ไตรมาสละครั้ง
3. อ่าน postmortem ของบริษัทอื่น สังเกตจุดตัดสินใจ
4. ฝึกเขียน status update ที่ผู้บริหารอ่านเข้าใจภายใน 3 บรรทัด

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ดึง log, สรุป timeline, เทียบ metric, อธิบายโค้ดที่ไม่คุ้น, ร่าง status update
- **Agent ทำแทนไม่ได้:** ตัดสินใจ rollback, ประสานคน, รับผิดชอบผลลัพธ์ — และห้ามให้ agent ทำ action ที่กระทบ production อัตโนมัติระหว่างเหตุ

## สัญญาณว่าทีมขาดทักษะนี้
- ไม่มีใครประกาศตัวเป็น IC ระหว่างเหตุ ทุกคนพิมพ์กันมั่ว
- MTTR ยาวเพราะเสียเวลาหาสาเหตุก่อนบรรเทา
- ไม่มี timeline ให้เขียน postmortem
