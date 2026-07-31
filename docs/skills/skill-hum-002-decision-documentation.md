---
id: SKILL-HUM-002
name: Decision Documentation
category: human
phases: [1, 2]
roles: [architect, tech-lead, product-owner, engineering-manager]
required_level: proficient
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-ARCH-001, SKILL-HUM-001]
review_by: 2027-01-31
---

# Decision Documentation

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-001 — Trade-off Analysis](skill-arch-001-tradeoff-analysis.md) · [SKILL-HUM-001 — Written Communication](skill-hum-001-written-communication.md)

## นิยาม
ความสามารถในการบันทึกการตัดสินใจให้คนในอนาคต (รวมถึงตัวเองในหกเดือนข้างหน้า) เข้าใจว่า **ทำไม** ถึงเลือกแบบนั้น ภายใต้บริบทและข้อจำกัดอะไร

## ทำไมสำคัญตอนนี้
สองเหตุผลที่แยกกัน หนึ่ง: เมื่อโค้ดถูกผลิตเร็วขึ้นมาก บริบทของการตัดสินใจสูญหายเร็วขึ้นตาม สอง: agent อ่านเอกสารเหล่านี้เป็นบริบท — การตัดสินใจที่ไม่ถูกบันทึกคือการตัดสินใจที่ agent จะละเมิดโดยไม่รู้ตัว

## ระดับ
### Foundation
- บันทึกว่าตัดสินใจอะไรไป

### Proficient
- บันทึกทางเลือกที่พิจารณาและเหตุผลที่ไม่เลือก
- ระบุข้อจำกัดและบริบท ณ เวลานั้น
- ระบุผลที่ตามมาทั้งด้านบวกและต้นทุนที่ยอมรับ

### Expert
- เชื่อมการตัดสินใจกับ fitness function ที่บังคับใช้จริง
- เขียนให้คนที่ไม่ได้อยู่ในตอนนั้นตัดสินได้ว่าเมื่อไหร่ควรทบทวนใหม่
- จัดการ ADR ที่ถูก supersede อย่างเป็นระบบ โดยไม่ลบประวัติ

## วิธีประเมิน
เอา ADR ที่เขาเขียนไว้ 6 เดือนก่อน ให้คนใหม่อ่าน แล้วถามว่า
1. เข้าใจไหมว่าทำไมถึงเลือกแบบนี้
2. รู้ไหมว่าเงื่อนไขอะไรเปลี่ยนแล้วควรทบทวนใหม่

ตอบไม่ได้ทั้งสองข้อ = ยังเป็น Foundation

## เส้นทางพัฒนา
1. เขียน ADR ย้อนหลังสำหรับการตัดสินใจที่กลับยาก 5 เรื่อง
2. บังคับ section Alternatives ในทุก ADR — ADR ที่ไม่มีคือบันทึกการประชุม
3. ผูก ADR แต่ละฉบับกับ test ที่บังคับใช้จริง
4. ทบทวน ADR เก่าทุกไตรมาส ดูว่าอันไหนควร supersede

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ร่าง ADR จากบทสนทนา, จัดโครงสร้าง, ค้นหา prior art, ตรวจว่ามี section ครบ
- **Agent ทำแทนไม่ได้:** ระบุเหตุผลที่แท้จริงของการเลือก โดยเฉพาะเหตุผลเชิงองค์กรที่ไม่ปรากฏในเอกสาร

## สัญญาณว่าทีมขาดทักษะนี้
- ถามว่า "ทำไมถึงทำแบบนี้" แล้วไม่มีใครตอบได้
- ตัดสินใจเรื่องเดิมซ้ำทุก 6 เดือน
- ADR มีแต่ Decision ไม่มี Context และ Alternatives
