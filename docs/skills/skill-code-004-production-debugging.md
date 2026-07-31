---
id: SKILL-CODE-004
name: Production Debugging
category: coding
phases: [7]
roles: [sre, backend-engineer, tech-lead]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-OPS-001, SKILL-OPS-003]
review_by: 2027-01-31
---

# Production Debugging

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-OPS-001 — Observability Design](skill-ops-001-observability-design.md) · [SKILL-OPS-003 — Root Cause Analysis](skill-ops-003-root-cause-analysis.md)

## นิยาม
ความสามารถในการหาสาเหตุของปัญหาในระบบจริงที่ทำซ้ำไม่ได้ ด้วยข้อมูลที่ไม่ครบ ภายใต้แรงกดดันด้านเวลา

## ทำไมสำคัญตอนนี้
**นี่คือทักษะที่ขึ้นค่าเงียบๆ แต่แรงที่สุด** เพราะเมื่อทีมเข้าใจโค้ดที่ตัวเองดูแลน้อยลง (comprehension decay จากโค้ดที่ agent เขียน) ความสามารถในการ debug ระบบที่ไม่ได้เขียนเองกลายเป็นสิ่งที่แยกทีมที่รอดจากทีมที่ล่มตอนตีสาม

## ระดับ
### Foundation
- อ่าน log และ stack trace ได้
- ทำตาม runbook ที่มีอยู่

### Proficient
- ตั้งสมมติฐานแล้วหาข้อมูลมาพิสูจน์หรือหักล้างอย่างเป็นระบบ
- ใช้ metric, trace, log ประกอบกันเพื่อจำกัดขอบเขตปัญหา
- รู้ว่าเมื่อไหร่ควรหยุดหาสาเหตุแล้วบรรเทาอาการก่อน

### Expert
- หาสาเหตุในระบบที่ไม่ได้เขียนเองได้
- แยก correlation ออกจาก causation ภายใต้แรงกดดัน
- รู้ว่าข้อมูลชิ้นไหนที่ "ไม่มี" คือเบาะแสสำคัญ

## วิธีประเมิน
ให้สถานการณ์: "p99 latency เพิ่มจาก 200ms เป็น 3s เมื่อ 40 นาทีที่แล้ว ไม่มี deploy ในช่วงนั้น" แล้วถามว่าจะดูอะไรก่อนตามลำดับ
- เริ่มจากเดาสาเหตุแล้วไปแก้เลย = Foundation
- ไล่จำกัดขอบเขตอย่างเป็นระบบ (ทุก endpoint หรือบางอัน / ทุก region หรือบางอัน / DB หรือ app) = Proficient ขึ้นไป
- ถามถึงสิ่งที่เปลี่ยนแปลงนอกระบบเรา (traffic pattern, upstream, cron, data growth) = Expert

## เส้นทางพัฒนา
1. เข้าร่วม incident แม้ไม่ได้เป็นเจ้าของระบบ — เรียนรู้จากคนที่เก่งกว่า
2. ฝึกอ่าน flame graph และ distributed trace
3. ทำ game day: จงใจสร้างปัญหาในระบบทดสอบแล้วให้ทีมหาสาเหตุ
4. อ่าน postmortem ของบริษัทอื่นเดือนละฉบับ แล้วลองเดาสาเหตุก่อนอ่านส่วนสรุป

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ดึง log, สรุป timeline, เทียบ metric ข้ามช่วงเวลา, อธิบายโค้ดที่ไม่คุ้น
- **Agent ทำแทนไม่ได้:** ตั้งสมมติฐานที่ดีจากบริบทที่ไม่ได้อยู่ในข้อมูล, ตัดสินใจว่าเมื่อไหร่ควรหยุดหาแล้ว rollback

## สัญญาณว่าทีมขาดทักษะนี้
- MTTR ยาวขึ้นเรื่อยๆ
- Incident จบด้วย "restart แล้วหาย" บ่อย
- มีคนคนเดียวที่ทุกคนต้องเรียกตอนระบบพัง
