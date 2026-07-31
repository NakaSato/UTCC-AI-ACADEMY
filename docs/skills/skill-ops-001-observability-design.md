---
id: SKILL-OPS-001
name: Observability Design
category: operations
phases: [1, 7]
roles: [sre, backend-engineer, architect, devops]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-CODE-004, SKILL-PROD-002]
review_by: 2027-01-31
---

# Observability Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md) · [SKILL-PROD-002 — Metric Design](skill-prod-002-metric-design.md)

## นิยาม
ความสามารถในการออกแบบระบบให้ตอบคำถามที่ยังไม่ได้ถูกถามได้ — ผ่าน metric, log และ trace ที่วางไว้ตั้งแต่ตอนออกแบบ ไม่ใช่ตอนเกิดเหตุ

## ทำไมสำคัญตอนนี้
เมื่อโค้ดส่วนใหญ่เขียนโดย agent และความเข้าใจของทีมที่มีต่อระบบลดลง observability กลายเป็นช่องทางหลักในการทำความเข้าใจระบบตัวเอง แทนที่จะเป็นความรู้ในหัวคน

## ระดับ
### Foundation
- เพิ่ม log และ metric ตามรูปแบบที่ทีมใช้อยู่
- ใช้ dashboard ที่มีอยู่ได้

### Proficient
- ออกแบบ metric ตาม RED/USE method
- ใส่ structured log ที่มี correlation id ตลอดเส้นทาง
- ตั้ง alert ที่ผูกกับอาการที่ผู้ใช้รู้สึก ไม่ใช่กับสาเหตุ
- เชื่อม metric, log และ trace ด้วย service, environment, version, release,
  trace และ correlation identifier เดียวกัน
- กำหนด owner และลิงก์ไปยัง runbook ให้ alert ที่ต้องลงมือทำทุกตัว

### Expert
- ออกแบบ SLO ที่สะท้อนประสบการณ์ผู้ใช้จริง และใช้ error budget ในการตัดสินใจ
- ออกแบบ trace ที่ตอบคำถามข้ามระบบได้
- ลด alert noise อย่างเป็นระบบโดยไม่ลดความปลอดภัย
- ออกแบบ sampling, redaction, access control และ retention โดยไม่บันทึก
  credential, request body, ข้อมูลผู้เรียน หรือ direct identifier ลง telemetry

## วิธีประเมิน
ถาม: "ถ้าผู้ใช้บอกว่าหน้าชำระเงินช้า คุณจะตอบภายใน 5 นาทีได้ไหมว่าช้าจริงไหม ช้าที่ไหน และกระทบผู้ใช้กี่คน"
ตอบไม่ได้ = observability ยังไม่พอ ไม่ว่าจะมี dashboard กี่อัน

## เส้นทางพัฒนา
1. เขียน SLO หนึ่งข้อสำหรับ service ที่ดูแล แล้ววัดจริงหนึ่งเดือน
2. ตรวจ alert ทั้งหมด: อันไหนที่ยิงแล้วไม่มีใครทำอะไร ให้ลบทิ้ง
3. ฝึกใส่ correlation id ตลอด request path แล้วลอง trace ปัญหาจริง
4. ทำ game day แล้วดูว่าข้อมูลที่มีพอหาสาเหตุไหม
5. ทำ controlled failure แล้วตรวจว่า dashboard แยก release ได้, trace เชื่อม
   ไปยัง log ได้ และ alert ไปถึง on-call พร้อม runbook

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ใส่ instrumentation ตามมาตรฐาน, สร้าง dashboard, เขียน query, สร้าง alert rule
- **Agent ทำแทนไม่ได้:** ตัดสินว่าอะไรคือ "ประสบการณ์ที่ดี" สำหรับผู้ใช้ของเรา ซึ่งเป็นฐานของ SLO

## สัญญาณว่าทีมขาดทักษะนี้
- รู้ว่าระบบพังจากผู้ใช้แจ้ง ไม่ใช่จาก alert
- Alert เยอะจนคนปิดการแจ้งเตือน
- มี log เยอะแต่ค้นหาอะไรไม่เจอเวลาต้องใช้
