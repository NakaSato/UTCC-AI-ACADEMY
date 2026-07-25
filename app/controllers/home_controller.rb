class HomeController < ApplicationController
  # The landing page is the app's front door — readable without an account.
  allow_unauthenticated_access only: :index

  # `/` is two pages: the catalog for a signed-in student, the public landing
  # page for everyone else. An admin's home is the admin screen instead, so the
  # front door — the logo, the first nav item, a bare `/` — lands them there.
  def index
    return redirect_to admin_path if authenticated? && Current.user.admin?
    return render_catalog if authenticated?

    landing
  end

  private
    def render_catalog
      @filter = filter_param
      @courses = CourseCatalog.all.select { |course| course.tagged?(@filter) }
      @filter_counts = CourseCatalog.filter_counts

      render :catalog
    end

    def filter_param
      requested = params[:filter].to_s.to_sym
      CourseCatalog::FILTERS.include?(requested) ? requested : :all
    end

    # Placeholder content until the real models land (see README "Next steps").
    def landing
      @topics = [
        { title: "AI คืออะไร เริ่มจากศูนย์",
          blurb: "ปัญญาประดิษฐ์ทำงานอย่างไร ต่างจากโปรแกรมทั่วไปตรงไหน อธิบายแบบไม่ต้องมีพื้นฐาน" },
        { title: "Prompt Engineering",
          blurb: "สั่งงาน AI ให้ได้ผลลัพธ์ที่ต้องการ เทคนิคที่ใช้ได้จริงกับงานเรียนและงานจริง" },
        { title: "Machine Learning เบื้องต้น",
          blurb: "โมเดลเรียนรู้จากข้อมูลอย่างไร พร้อมตัวอย่างที่รันได้เองบนเครื่อง" },
        { title: "สร้างแอปด้วย AI",
          blurb: "ต่อ API เข้ากับโปรเจกต์ของคุณ ตั้งแต่ chatbot ไปจนถึงเครื่องมือช่วยทำงาน" },
        { title: "จริยธรรมและการใช้ AI อย่างรับผิดชอบ",
          blurb: "ลิขสิทธิ์ อคติของโมเดล และการอ้างอิงผลงาน AI ในงานวิชาการ" },
        { title: "AI ในโลกธุรกิจ",
          blurb: "กรณีศึกษาจริงจากภาคธุรกิจไทย และทักษะที่ตลาดงานกำลังมองหา" }
      ]

      @tracks = [
        { title: "ผู้เริ่มต้น", level: "beginner", badge: "เริ่มต้น", weeks: "4 สัปดาห์",
          blurb: "ยังไม่เคยเขียนโปรแกรมก็เรียนได้ ปูพื้นฐานแนวคิด AI และการใช้เครื่องมือ" },
        { title: "นักศึกษาสายวิศวกรรม", level: "beginner", badge: "เริ่มต้น", weeks: "6 สัปดาห์",
          blurb: "Python, ข้อมูล และการเรียกใช้โมเดลผ่าน API สำหรับงานโปรเจกต์" },
        { title: "สร้างโปรเจกต์แรก", level: "intermediate", badge: "ระดับกลาง", weeks: "8 สัปดาห์",
          blurb: "ลงมือทำโปรเจกต์จริงตั้งแต่ออกแบบจนนำไปใช้ พร้อมรีวิวจากรุ่นพี่" },
        { title: "Data & Machine Learning", level: "intermediate", badge: "ระดับกลาง", weeks: "8 สัปดาห์",
          blurb: "เตรียมข้อมูล ฝึกโมเดล และวัดผลอย่างถูกวิธี" },
        { title: "AI Agent และระบบอัตโนมัติ", level: "advanced", badge: "ขั้นสูง", weeks: "10 สัปดาห์",
          blurb: "ออกแบบ agent ที่เรียกใช้เครื่องมือได้เอง และต่อเข้ากับงานจริง" },
        { title: "งานวิจัยและการต่อยอด", level: "advanced", badge: "ขั้นสูง", weeks: "ต่อเนื่อง",
          blurb: "อ่านเปเปอร์ ทำซ้ำผลการทดลอง และเตรียมตัวสู่ระดับบัณฑิตศึกษา" }
      ]

      @shares = [
        { title: "สรุปสิ่งที่ได้จากการลองทำ chatbot ตัวแรก", author: "ปีที่ 1 · วิศวกรรมคอมพิวเตอร์",
          tag: "โปรเจกต์", date: "20 ก.ค. 2026" },
        { title: "รวมเครื่องมือ AI ฟรีที่ใช้ช่วยทำรายงานได้จริง", author: "ปีที่ 2 · วิศวกรรมโลจิสติกส์",
          tag: "เครื่องมือ", date: "15 ก.ค. 2026" },
        { title: "บันทึกการเรียน: กว่าจะเข้าใจ neural network", author: "ปีที่ 1 · วิศวกรรมธุรกิจ",
          tag: "บันทึกการเรียน", date: "09 ก.ค. 2026" }
      ]

      @events = [
        { title: "AI Study Jam สำหรับน้องปี 1", when: "ทุกวันพุธ 17:00", where: "ห้อง Lab อาคาร 21" },
        { title: "Workshop: สร้างแอปแรกด้วย AI ใน 3 ชั่วโมง", when: "8 ส.ค. 2026", where: "UTCC AI Institute" },
        { title: "Show & Tell แชร์โปรเจกต์ประจำเดือน", when: "สิ้นเดือน", where: "ออนไลน์" }
      ]

      @faqs = [
        { q: "ไม่มีพื้นฐานเขียนโปรแกรมเลย เริ่มตรงไหนดี",
          a: "เริ่มที่เส้นทาง “ผู้เริ่มต้น” ได้เลย เนื้อหาปูพื้นฐานตั้งแต่แนวคิดพื้นฐานของ AI ไปจนถึงการใช้เครื่องมือ โดยยังไม่ต้องเขียนโค้ด" },
        { q: "ใช้ AI ทำการบ้านได้ไหม ผิดกฎหรือเปล่า",
          a: "ขึ้นกับกติกาของแต่ละวิชา หลักการที่แนะนำคือใช้ AI เป็นผู้ช่วยเรียนรู้ ไม่ใช่ส่งงานแทน และต้องอ้างอิงเสมอเมื่อใช้ผลลัพธ์จาก AI ดูรายละเอียดในหัวข้อจริยธรรม" },
        { q: "อยากแชร์โปรเจกต์ให้เพื่อนดู ต้องทำอย่างไร",
          a: "ส่งโปรเจกต์เข้ามาในหน้าชุมชน เล่าว่าทำอะไร ติดปัญหาตรงไหน และเรียนรู้อะไรบ้าง ไม่ต้องรอให้เสร็จสมบูรณ์ก็แชร์ได้" },
        { q: "เปิดให้นักศึกษาคณะอื่นเข้าร่วมไหม",
          a: "เปิดสำหรับนักศึกษา UTCC ทุกคณะ เนื้อหาออกแบบมาให้เริ่มได้โดยไม่ต้องมีพื้นฐานวิศวกรรม" }
      ]
    end
end
