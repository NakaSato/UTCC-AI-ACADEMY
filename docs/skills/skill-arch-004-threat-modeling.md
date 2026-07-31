---
id: SKILL-ARCH-004
name: Threat Modeling
category: architecture
phases: [1]
roles: [security-engineer, architect, tech-lead]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-BLD-002, SKILL-AI-004]
review_by: 2027-01-31
---

# Threat Modeling

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-BLD-002 — Supply Chain Security](skill-bld-002-supply-chain-security.md) · [SKILL-AI-004 — Agent Orchestration](skill-ai-004-agent-orchestration.md)

## นิยาม
ความสามารถในการมองระบบจากมุมของผู้โจมตี ระบุได้ว่าอะไรมีค่าพอให้ถูกโจมตี ทางเข้ามีที่ไหนบ้าง และสิ่งที่เราถือว่า "เชื่อถือได้" นั้นเชื่อได้จริงหรือไม่

## ทำไมสำคัญตอนนี้
ระบบที่มี AI agent เพิ่ม attack surface ใหม่ทั้งชุด — prompt injection ผ่าน ticket/PR comment, credential ที่ agent เข้าถึงได้, dependency ที่ agent เพิ่มเอง, egress ที่ไม่มีใครจำกัด ทักษะนี้จึงไม่ใช่เรื่องของทีม security อย่างเดียวอีกต่อไป

## ระดับ
### Foundation
- รู้จัก OWASP Top 10 และตรวจได้ว่าโค้ดมีรูปแบบเสี่ยงที่รู้จักหรือไม่

### Proficient
- ทำ STRIDE หรือกรอบเทียบเท่ากับ feature ใหม่ได้
- ระบุ trust boundary ในระบบได้ชัดเจน
- แยก authentication ออกจาก authorization ในการออกแบบ

### Expert
- มองเห็นช่องโหว่ที่เกิดจากการต่อกันของส่วนที่แต่ละส่วนปลอดภัยดี
- ประเมินได้ว่าการควบคุมไหนคุ้มค่าและไหนเป็นพิธีกรรม
- ออกแบบระบบที่จำกัดความเสียหายเมื่อถูกเจาะแล้ว ไม่ใช่แค่กันไม่ให้ถูกเจาะ

## วิธีประเมิน
ให้ออกแบบ: "agent อ่าน ticket จาก Jira แล้วเขียนโค้ดตามนั้น" แล้วถามว่ามีความเสี่ยงอะไรบ้าง
- ไม่พูดถึง prompt injection เลย = Foundation
- พูดถึง injection และเสนอให้แยก instruction ออกจาก data = Proficient
- พูดถึง egress control, credential scope, และการจำกัดความเสียหายหลังถูกเจาะ = Expert

## เส้นทางพัฒนา
1. ทำ threat model ให้ feature ที่กำลังจะทำ ใช้เวลา 30 นาที ด้วยกรอบ STRIDE
2. วาด trust boundary ของระบบปัจจุบัน แล้วถามทีละเส้นว่า "ถ้าฝั่งนั้นถูกยึด เกิดอะไร"
3. อ่าน incident report ของบริษัทอื่นเดือนละหนึ่งฉบับ
4. ฝึกโจมตีระบบตัวเองในสภาพแวดล้อมทดสอบ

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ตรวจหา pattern ที่รู้จัก, สรุป CVE, ร่าง threat model เบื้องต้นจาก architecture diagram
- **Agent ทำแทนไม่ได้:** ประเมินว่าอะไรมีค่าพอให้ถูกโจมตีในบริบทธุรกิจของเรา, ตัดสินว่าความเสี่ยงระดับไหนที่ยอมรับได้

## สัญญาณว่าทีมขาดทักษะนี้
- Security เข้ามาเกี่ยวข้องครั้งแรกตอนก่อน release
- ไม่มีใครตอบได้ว่า agent เข้าถึงอะไรได้บ้าง
- คิดว่า "ระบบภายใน" แปลว่าปลอดภัย
