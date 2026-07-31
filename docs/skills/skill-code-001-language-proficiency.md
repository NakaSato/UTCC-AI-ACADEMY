---
id: SKILL-CODE-001
name: Language Proficiency
category: coding
phases: [3]
roles: [backend-engineer, frontend-engineer, devops]
required_level: proficient
agent_delegable: true
agent_trend: declining
related: [SKILL-CODE-002, SKILL-AI-002]
review_by: 2027-01-31
---

# Language Proficiency

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-002 — API Design](skill-code-002-api-design.md) · [SKILL-AI-002 — Agent Output Verification](skill-ai-002-agent-output-verification.md)

## นิยาม
ความคล่องในภาษาและ ecosystem ที่ใช้ — idiom, standard library, เครื่องมือ, รูปแบบที่ชุมชนยอมรับ และข้อจำกัดที่ต้องรู้

## ทำไมสำคัญตอนนี้
**ทักษะนี้กำลังลดค่าลงในแง่ของการผลิต** แต่ **ยังตัดไม่ได้ในแง่ของการตรวจสอบ** — ถ้าอ่านโค้ดที่ agent เขียนไม่ออก ก็ verify ไม่ได้ และเมื่อ verify ไม่ได้ ทั้ง flow พังทันที

ข้อควรระวังที่สำคัญ: ทักษะ verification สร้างจากประสบการณ์การเขียนผิดด้วยตัวเองเท่านั้น คนที่ข้ามขั้นการเขียนโค้ดเองไปเลยจะไม่มีวันพัฒนา SKILL-AI-002 ได้

## ระดับ
### Foundation
- เขียนโค้ดที่ทำงานได้ตามตัวอย่างที่มี
- อ่านโค้ดของคนอื่นในภาษานั้นเข้าใจ

### Proficient
- เขียนโค้ดที่ idiomatic โดยไม่ต้องดูตัวอย่าง
- รู้จักข้อจำกัดของ runtime (GC, GIL, memory model, async model)
- เลือก data structure ได้เหมาะกับปัญหา

### Expert
- เข้าใจว่าโค้ดถูกแปลและทำงานอย่างไรจริงๆ ในระดับล่าง
- ปรับ performance บนพื้นฐานของการวัด ไม่ใช่การเดา
- รู้ว่า idiom ข้อไหนควรละเมิดและเมื่อไหร่

## วิธีประเมิน
ให้อ่านโค้ด 150 บรรทัดที่ agent เขียน แล้วให้ชี้จุดที่มีปัญหาภายใน 10 นาที
วัดที่ **ความสามารถในการอ่าน** ไม่ใช่ความสามารถในการเขียน — นี่คือสิ่งที่เปลี่ยนไปจากเดิม

## เส้นทางพัฒนา
1. อ่าน source code ของ library ที่ใช้บ่อย
2. เขียนโค้ดเองโดยไม่ใช้ agent สัปดาห์ละครั้ง เพื่อรักษาความรู้สึกว่าอะไรยากอะไรง่าย
3. ทำ code review ของคนอื่นให้มากกว่าเขียนเอง
4. ศึกษา runtime ของภาษาที่ใช้อย่างน้อยหนึ่งชั้นลึกกว่าที่ใช้งานอยู่

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน implementation, refactor, แปลงภาษา, boilerplate, unit test — เกือบทั้งหมด
- **Agent ทำแทนไม่ได้:** ตัดสินว่าโค้ดที่มันเขียนถูกหรือไม่

## สัญญาณว่าทีมขาดทักษะนี้
- Review ใช้เวลาสั้นผิดปกติเมื่อเทียบกับขนาด diff
- ไม่มีใครอธิบายได้ว่าโค้ดส่วนนี้ทำงานอย่างไร
