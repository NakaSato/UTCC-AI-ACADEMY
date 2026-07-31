---
id: SKILL-PROD-002
name: Metric Design
category: product
phases: [0, 8]
roles: [product-owner, data-engineer, business-analyst]
required_level: proficient
agent_delegable: assisted
agent_trend: rising
related: [SKILL-PROD-001, SKILL-OPS-001]
review_by: 2027-01-31
---

# Metric Design

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-PROD-001 — Problem Framing](skill-prod-001-problem-framing.md) · [SKILL-OPS-001 — Observability Design](skill-ops-001-observability-design.md)

## นิยาม
ความสามารถในการออกแบบตัววัดที่ (1) สะท้อนผลลัพธ์ที่ต้องการจริง (2) เก็บข้อมูลได้จริงในระบบที่มีอยู่ (3) ไม่ถูกบิดเบือนได้ง่ายเมื่อคนรู้ว่ากำลังถูกวัด

## ทำไมสำคัญตอนนี้
เมื่อ throughput ของการสร้างสูงขึ้นมาก การวัดผลกลายเป็นเบรกเพียงอย่างเดียวที่เหลืออยู่ ทีมที่วัดไม่เป็นจะเร่งไปผิดทางได้เร็วกว่าเดิมหลายเท่า

## ระดับ
### Foundation
- แยก output (จำนวนที่ทำ) ออกจาก outcome (ผลที่เกิด) ได้
- อ่าน dashboard ที่มีอยู่แล้วเข้าใจ

### Proficient
- ออกแบบ metric ใหม่พร้อมระบุ baseline, target และวิธีเก็บข้อมูล
- รู้จัก counter-metric (ตัววัดที่คอยกันไม่ให้ optimize ตัวหลักจนเสียอย่างอื่น)
- ตรวจสอบได้ว่า metric ที่เสนอ instrument ได้จริงก่อนเขียนลง PRD

### Expert
- มองเห็นล่วงหน้าว่า metric นี้จะถูก game อย่างไร แล้วออกแบบกันไว้
- แยกความสัมพันธ์เชิงสหสัมพันธ์ออกจากเชิงสาเหตุได้
- ตัดสินใจได้ว่าเมื่อไหร่ metric ควรถูกเลิกใช้

## วิธีประเมิน
ให้โจทย์: "เราอยากให้ผู้ใช้มีส่วนร่วมมากขึ้น" แล้วดูว่าเขา:
1. เสนอ metric อะไร และเสนอ counter-metric ด้วยไหม
2. ตอบได้ไหมว่าเก็บข้อมูลจากไหน มีอยู่แล้วหรือต้องสร้าง
3. ตอบได้ไหมว่าถ้าทีมอยากปั่นตัวเลขนี้ ทำได้ยังไง

คนที่เสนอ "จำนวน DAU" โดยไม่มี counter-metric = Foundation

## เส้นทางพัฒนา
1. หยิบ metric ที่ทีมใช้อยู่ ลองหาวิธี game ให้ได้ 3 วิธีต่อ metric
2. ฝึกเขียน metric spec: นิยาม, สูตร, แหล่งข้อมูล, baseline, counter-metric
3. อ่านเรื่อง Goodhart's Law และตัวอย่าง metric ที่พังในอุตสาหกรรม
4. จับคู่กับ Data Engineer ทำ instrumentation จริงหนึ่งรอบเต็ม

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** เขียน query, สร้าง dashboard, ตรวจว่าข้อมูลมีอยู่ไหม, เสนอ metric ที่คนอื่นในอุตสาหกรรมใช้
- **Agent ทำแทนไม่ได้:** ตัดสินว่า metric ไหนสะท้อนคุณค่าจริงในบริบทของเรา, ตีความว่าตัวเลขที่ได้แปลว่าอะไร

## สัญญาณว่าทีมขาดทักษะนี้
- PRD มีคำว่า "ผู้ใช้จะพอใจขึ้น" โดยไม่มีตัวเลข
- ตัวเลขที่รายงานสวยขึ้นทุกไตรมาสแต่ธุรกิจไม่ดีขึ้น
- ไม่มีใครรู้ว่า metric ตัวนี้คำนวณจากอะไรกันแน่
