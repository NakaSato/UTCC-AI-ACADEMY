---
id: SKILL-OPS-003
name: Root Cause Analysis
category: operations
phases: [7]
roles: [sre, tech-lead, engineering-manager, architect]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-OPS-002, SKILL-CODE-004, SKILL-HUM-002]
review_by: 2027-01-31
---

# Root Cause Analysis

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-OPS-002 — Incident Response](skill-ops-002-incident-response.md) · [SKILL-CODE-004 — Production Debugging](skill-code-004-production-debugging.md) · [SKILL-HUM-002 — Decision Documentation](skill-hum-002-decision-documentation.md)

## นิยาม
ความสามารถในการวิเคราะห์หลังเหตุการณ์เพื่อหาสาเหตุเชิงระบบ ไม่ใช่เชิงบุคคล และแปลงเป็นการเปลี่ยนแปลงที่ป้องกันการเกิดซ้ำได้จริง

## ทำไมสำคัญตอนนี้
เมื่อโค้ดถูกผลิตเร็วขึ้น รูปแบบความผิดพลาดจะซ้ำเร็วขึ้นตาม RCA ที่ดีจะเปลี่ยน bug หนึ่งตัวเป็น fitness function หรือ gate ที่กันทั้งประเภทได้ — ซึ่งเป็นวิธีเดียวที่คุณภาพจะตามทันปริมาณ

## ระดับ
### Foundation
- เขียน timeline ของเหตุการณ์ได้ครบ
- ระบุสาเหตุโดยตรงได้

### Proficient
- ใช้เทคนิคอย่าง 5 Whys โดยไม่หยุดที่ "คนทำพลาด"
- แยก contributing factor ออกจาก root cause
- เสนอ action item ที่วัดผลได้และมีเจ้าของ

### Expert
- วิเคราะห์เชิงระบบ: ทำไมกระบวนการถึงปล่อยให้เกิดสิ่งนี้ได้
- เห็นรูปแบบข้าม incident หลายครั้งที่ดูไม่เกี่ยวกัน
- แปลง finding เป็น gate อัตโนมัติแทนที่จะเป็นการเตือนให้ระวัง

## วิธีประเมิน
ให้ postmortem ที่สรุปว่า "developer ลืมเพิ่ม index" แล้วถามว่าจะวิเคราะห์ต่ออย่างไร
- ยอมรับคำตอบนั้น = Foundation
- ถามว่าทำไมระบบถึงปล่อยให้ deploy ได้โดยไม่มีใครสังเกต = Proficient
- เสนอ gate อัตโนมัติที่ตรวจ query plan ใน CI = Expert

## เส้นทางพัฒนา
1. เขียน postmortem ทุกครั้งแม้เหตุเล็ก แล้วบังคับตัวเองให้ถาม "ทำไม" ห้าชั้น
2. ตรวจ action item จาก postmortem เก่า — กี่ % ที่ทำจริง และกี่ % ที่กลายเป็น automation
3. หา pattern จาก incident 10 ครั้งล่าสุด
4. ฝึกเขียน blameless postmortem — ภาษาที่ใช้กำหนดว่าคนจะพูดความจริงหรือไม่

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** รวบรวม timeline จาก log และ chat, หา correlation, ร่างเอกสาร, ค้น incident คล้ายกันในอดีต
- **Agent ทำแทนไม่ได้:** วิเคราะห์สาเหตุเชิงองค์กร, ตัดสินว่า action item ไหนคุ้มที่จะทำ

## สัญญาณว่าทีมขาดทักษะนี้
- Postmortem จบที่ "จะระมัดระวังมากขึ้น"
- Incident แบบเดิมเกิดซ้ำภายในหกเดือน
- Action item ค้างไม่มีใครทำ
