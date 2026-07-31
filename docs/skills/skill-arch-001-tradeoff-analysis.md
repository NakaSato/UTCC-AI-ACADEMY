---
id: SKILL-ARCH-001
name: Trade-off Analysis
category: architecture
phases: [1]
roles: [architect, tech-lead, security-engineer]
required_level: expert
agent_delegable: assisted
agent_trend: rising-critical
related: [SKILL-ARCH-002, SKILL-HUM-002]
review_by: 2027-01-31
---

# Trade-off Analysis

> [Canonical Skill Library](../skills-library-README.md) ·
> [Skill Directory](README.md) ·
> [Project Development Flow](../development-flow.md) ·
> [Workflow Guide for All Roles](../system-development-flow-role-guide.md) ·
> [System Development Flow Master](../system-development-flow-master.md)

> Related skills: [SKILL-ARCH-002 — Boundary & Module Design](skill-arch-002-boundary-design.md) · [SKILL-HUM-002 — Decision Documentation](skill-hum-002-decision-documentation.md)

## นิยาม
ความสามารถในการเปรียบเทียบทางเลือกทางเทคนิคโดยระบุได้ว่า **แลกอะไรไปเพื่อได้อะไร** และตัดสินใจได้ทั้งที่ทุกทางเลือกมีข้อเสีย

## ทำไมสำคัญตอนนี้
Agent เสนอทางเลือกได้เก่งมาก และเสนอได้เยอะกว่าที่มนุษย์คิดออกเอง แต่มันไม่รู้บริบทของทีม ข้อจำกัดขององค์กร และสิ่งที่เราแบกไหว ทักษะนี้จึงเป็นคอขวดใหม่ที่แท้จริง

## ระดับ
### Foundation
- เปรียบเทียบทางเลือกได้เมื่อมีตารางให้กรอก
- ระบุข้อดีข้อเสียที่เห็นชัดได้

### Proficient
- สร้างเกณฑ์เปรียบเทียบเองที่ตรงกับปัญหา ไม่ใช่เกณฑ์ทั่วไป
- ระบุต้นทุนระยะยาว (operational cost, cognitive load) ไม่ใช่แค่ต้นทุนตอนสร้าง
- แยกได้ว่าการตัดสินใจนี้กลับง่ายหรือกลับยาก

### Expert
- ประเมินได้ว่าทางเลือกไหนจะพังก่อนภายใต้เงื่อนไขอะไร
- ตัดสินใจได้เร็วกับเรื่องที่กลับง่าย และช้าลงกับเรื่องที่กลับยาก
- มองเห็นทางเลือกที่ไม่มีใครเสนอ รวมถึง "ไม่ทำอะไรเลย"

## วิธีประเมิน
ให้โจทย์จริงที่ทีมเคยตัดสินใจไปแล้ว เช่น "จะใช้ message queue ตัวไหน" แล้วดูว่าเขา:
1. ถามถึง throughput, ordering guarantee, ทีมมีประสบการณ์อะไร ก่อนเสนอชื่อ product
2. พูดถึงต้นทุนการดูแลระยะยาว ไม่ใช่แค่ feature
3. ระบุได้ว่าถ้าเลือกผิดแล้วเปลี่ยนยากแค่ไหน

คนที่เริ่มด้วยชื่อ product ทันที = ยังไม่ถึง Proficient

## เส้นทางพัฒนา
1. เขียน ADR ย้อนหลังสำหรับการตัดสินใจที่ทำไปแล้ว 5 เรื่อง บังคับให้มี section Alternatives
2. ฝึกถามคำถาม "แล้วเราแลกอะไรไป" กับทุกข้อเสนอในทีม
3. ติดตามผลการตัดสินใจเก่า 6 เดือนย้อนหลัง — อันไหนที่คิดผิด และผิดเพราะประเมินอะไรพลาด
4. ให้ agent เสนอทางเลือกแล้วฝึกหาข้อเสียที่มันไม่ได้พูดถึง

## ความสัมพันธ์กับ Agent
- **Agent ทำแทนได้:** ค้นหาทางเลือกที่มีอยู่, สร้างตารางเปรียบเทียบเบื้องต้น, หา prior art ใน codebase
- **Agent ทำแทนไม่ได้:** ชั่งน้ำหนักตามบริบทของทีม, รับผลของการเลือก, รู้ว่าองค์กรแบกอะไรไหว

## สัญญาณว่าทีมขาดทักษะนี้
- ADR มีแต่ Decision ไม่มี Alternatives
- เลือกเทคโนโลยีตามที่กำลังเป็นกระแส
- ทุกการตัดสินใจใช้เวลาเท่ากันหมด ไม่ว่าจะกลับง่ายหรือกลับยาก
