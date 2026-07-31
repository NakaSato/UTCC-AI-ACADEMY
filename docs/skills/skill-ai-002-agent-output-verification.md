---
id: SKILL-AI-002
name: Agent Output Verification
category: ai-era
phases: [3, 4]
roles: [backend-engineer, frontend-engineer, tech-lead, qa, agent-orchestrator]
required_level: expert
agent_delegable: false
agent_trend: new
related: [SKILL-CODE-001, SKILL-AI-003, SKILL-TEST-001]
review_by: 2027-01-31
---

# Agent Output Verification

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-CODE-001 — Language Proficiency](skill-code-001-language-proficiency.md) · [SKILL-AI-003 — Review at Scale](skill-ai-003-review-at-scale.md) · [SKILL-TEST-001 — Test Design](skill-test-001-test-design.md)

## นิยาม
ความสามารถในการอ่านผลงานของ agent แล้วตัดสินได้ว่ามันทำในสิ่งที่ตั้งใจจริงหรือไม่ — โดยเฉพาะการจับ **โค้ดที่ดูถูกต้องแต่ไม่ตรงเจตนา**

## ทำไมสำคัญตอนนี้
นี่คือทักษะที่สำคัญที่สุดในกลุ่ม AI-era และเป็นคอขวดใหม่ของทั้งระบบ ความเสี่ยงหลักไม่ใช่โค้ดที่พัง — โค้ดที่พังถูกจับโดย CI แต่เป็นโค้ดที่ **ผ่านทุก gate แล้วยังผิด** เพราะมันตอบโจทย์ที่ agent เข้าใจ ไม่ใช่โจทย์ที่เราตั้งใจ

## ระดับ
### Foundation
- อ่านโค้ดที่ agent เขียนเข้าใจ
- ตรวจว่าผ่าน test และ lint หรือไม่

### Proficient
- ตรวจเทียบกับ spec ทีละข้อ ไม่ใช่อ่านผ่านๆ
- รู้จุดที่ agent มักพลาดซ้ำๆ: กรณีว่าง, error path, off-by-one ที่ขอบเขต, concurrency, การ catch exception กว้างเกินไป, การเพิ่ม dependency โดยไม่จำเป็น
- ตรวจสิ่งที่ **ไม่ได้ทำ** ด้วย ไม่ใช่แค่สิ่งที่ทำ

### Expert
- จับ "โค้ดที่ถูกทางเทคนิคแต่ผิดทาง domain" ได้
- ประเมินผลระยะยาวของ pattern ที่ถูกเพิ่มเข้ามา
- รู้ว่าเมื่อไหร่ควรทิ้ง diff แล้วให้เริ่มใหม่ แทนที่จะไล่แก้

## วิธีประเมิน
ให้ diff จาก agent ที่มีปัญหาฝังไว้ 5 จุด โดย 2 จุดเป็นเรื่อง domain ไม่ใช่เรื่อง syntax และ test ผ่านหมด
- เจอเฉพาะจุดที่เป็น technical = Proficient
- เจอจุดที่เป็น domain ด้วย = Expert
- บอกว่า "ดูดี" = ยังไม่ควรรีวิวงาน Tier C

## เส้นทางพัฒนา
1. ให้ agent เขียนโค้ดที่คุณรู้คำตอบอยู่แล้ว แล้วหาจุดที่มันเบี่ยง ทำซ้ำจนเห็นรูปแบบ
2. **เก็บ log ส่วนตัวว่า agent พลาดตรงไหนบ้าง** แล้วสร้าง checklist จากรูปแบบที่ซ้ำ
3. ฝึกอ่าน diff โดยเทียบกับ spec ทีละบรรทัด ไม่ใช่อ่านโค้ดอย่างเดียว
4. ยังต้องเขียนโค้ดเองบ้าง — ทักษะนี้สร้างจากประสบการณ์การเขียนผิดด้วยตัวเองเท่านั้น

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ไม่ได้ — agent ตรวจงาน agent คือระบบรับรองตัวเอง
- **หมายเหตุ:** ใช้ agent ตัวที่สองช่วยชี้จุดน่าสงสัยได้ แต่การตัดสินต้องเป็นของมนุษย์

## สัญญาณว่าทีมขาดทักษะนี้
- Review depth (เวลารีวิว ÷ ขนาด diff) ลดลงเรื่อยๆ
- Approve ภายในไม่กี่นาทีสำหรับ diff ขนาดใหญ่
- Escaped defect เพิ่มขึ้นแม้ coverage สูง
