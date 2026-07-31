---
id: SKILL-HUM-003
name: Review Feedback
category: human
phases: [3]
roles: [tech-lead, engineering-manager, backend-engineer, frontend-engineer]
required_level: proficient
agent_delegable: false
agent_trend: rising
related: [SKILL-AI-002, SKILL-HUM-001]
review_by: 2027-01-31
---

# Review Feedback

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md) · [SKILL-HUM-001 — Written Communication](skill-hum-001-written-communication.md)

## นิยาม
ความสามารถในการให้ความเห็นต่องานของคนอื่นในแบบที่ทำให้งานดีขึ้นและคนอยากทำงานต่อ — แยกความเห็นที่ต้องแก้ ออกจากความเห็นที่เป็นรสนิยม

## ทำไมสำคัญตอนนี้
บทบาทเปลี่ยนไปสองอย่าง หนึ่ง: เวลาที่เคยใช้เขียนโค้ดย้ายมาอยู่ที่การรีวิว ทำให้ทักษะนี้กินสัดส่วนของงานมากขึ้น สอง: เมื่อคนส่ง diff ที่ agent เขียน การให้ feedback ต้องแยกให้ออกว่ากำลังวิจารณ์การตัดสินใจของคน หรือวิจารณ์ output ของเครื่อง — ซึ่งเปลี่ยนทั้งน้ำเสียงและเนื้อหาที่ควรพูด

## ระดับ
### Foundation
- ชี้จุดที่มีปัญหาได้ชัดเจน
- ใช้ภาษาสุภาพ

### Proficient
- แยกระดับความเห็น: ต้องแก้ / ควรพิจารณา / แค่ความเห็น (nit)
- อธิบายเหตุผลไม่ใช่แค่บอกให้เปลี่ยน
- ชมสิ่งที่ทำได้ดีด้วย ไม่ใช่ชี้แต่ปัญหา

### Expert
- ให้ feedback ที่สอนหลักการ ไม่ใช่แก้เฉพาะกรณี
- รู้ว่าเมื่อไหร่ควรคุยด้วยเสียงแทนการพิมพ์ (เมื่อมีความเห็นต่างเชิงโครงสร้าง)
- สร้างวัฒนธรรมที่คนกล้าส่งงานที่ยังไม่สมบูรณ์มาให้ดู

## วิธีประเมิน
ดู review comment ย้อนหลัง 20 ข้อ แล้วนับ:
- กี่ % ที่ระบุระดับความสำคัญ
- กี่ % ที่อธิบายเหตุผล
- กี่ % ที่เป็นเรื่องรสนิยมล้วนแต่เขียนเหมือนเป็นข้อบังคับ

## เส้นทางพัฒนา
1. ใช้ prefix ทุกความเห็น: `[must]` `[consider]` `[nit]`
2. บังคับตัวเองให้เขียนเหตุผลอย่างน้อยหนึ่งประโยคต่อความเห็น
3. ทบทวน: ความเห็นที่ให้ไปทำให้งานดีขึ้นจริงกี่ข้อ
4. ถามคนที่รับ feedback ว่าข้อไหนมีประโยชน์ที่สุดและข้อไหนกวนใจ

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ชี้ปัญหาทางเทคนิคที่ตรวจได้อัตโนมัติ (ควรย้ายไปเป็น linter แทนที่จะเป็น comment)
- **Agent ทำแทนไม่ได้:** สอน, สร้างความไว้ใจ, ตัดสินว่าเรื่องนี้คุ้มที่จะยืนกรานหรือไม่

## สัญญาณว่าทีมขาดทักษะนี้
- Review comment ส่วนใหญ่เป็นเรื่อง format ที่ linter ควรจับ
- คนกลัวการส่ง PR
- ความเห็นเรื่องรสนิยมทำให้ PR ค้างหลายวัน
