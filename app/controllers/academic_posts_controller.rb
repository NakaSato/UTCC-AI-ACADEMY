class AcademicPostsController < ApplicationController
  allow_only :student, :instructor
  allow_only :instructor, only: :publish

  def index
    owned = Current.user.academic_posts.select(:id)
    shared = Current.user.academic_post_memberships.active.select(:academic_post_id)
    @posts = AcademicPost.where(id: owned).or(AcademicPost.where(id: shared)).order(updated_at: :desc)
  end

  def new
    @post = Current.user.academic_posts.new
  end

  def create
    @post = Current.user.academic_posts.new(post_params.except(:lock_version))

    AcademicPost.transaction do
      @post.save!
      @post.revisions.create!(author: Current.user, version: @post.lock_version,
                              title: @post.title, body: @post.body)
    end

    redirect_to @post, notice: t("flash.academic_post_created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
    find_accessible_post
  end

  def export
    find_accessible_post
    title = ERB::Util.html_escape(@post.title.presence || t("academic.untitled"))
    body = ::AcademicPostContentSanitizer.sanitize(@post.body.presence || "<p>#{t("academic.no_body")}</p>")
    document = <<~HTML
      <!doctype html>
      <html lang="#{I18n.locale}">
        <head>
          <meta charset="utf-8">
          <title>#{title}</title>
        </head>
        <body>
          <article>
            <h1>#{title}</h1>
            #{body}
          </article>
        </body>
      </html>
    HTML

    send_data document, filename: "academic-post-#{@post.id}.html", type: "text/html"
  end

  def edit
    find_accessible_post
    return redirect_to @post, alert: t("flash.academic_post_forbidden") unless @post.editable_by?(Current.user)
    return if @post.draft?

    redirect_to @post, alert: t("flash.academic_post_not_editable")
  end

  def update
    find_accessible_post
    return redirect_to @post, alert: t("flash.academic_post_forbidden") unless @post.editable_by?(Current.user)
    return redirect_to(@post, alert: t("flash.academic_post_not_editable")) unless @post.draft?

    @post.save_draft!(author: Current.user,
                      expected_lock_version: post_params[:lock_version],
                      attributes: post_params.slice(:title, :body))
    redirect_to @post, notice: t("flash.academic_post_saved")
  rescue ActiveRecord::StaleObjectError
    @post = AcademicPost.find(@post.id)
    @conflict = true
    render :edit, status: :conflict
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def submit
    find_owned_post
    return redirect_to @post, alert: t("flash.academic_post_not_editable") unless @post.draft?
    return redirect_to @post, alert: t("flash.academic_post_not_ready") unless @post.ready_for_review?

    @post.update!(status: :review)
    redirect_to @post, notice: t("flash.academic_post_submitted")
  rescue ActiveRecord::StaleObjectError
    redirect_to @post, alert: t("flash.academic_post_conflict")
  end

  def publish
    @post = AcademicPost.find(params[:id])
    return redirect_to academic_posts_path, alert: t("flash.academic_post_forbidden") unless @post.review?

    @post.update!(status: :published)
    redirect_to @post, notice: t("flash.academic_post_published")
  rescue ActiveRecord::StaleObjectError
    redirect_to @post, alert: t("flash.academic_post_conflict")
  end

  def pictures
    find_accessible_post
    return render json: { error: t("flash.academic_post_forbidden") }, status: :forbidden unless @post.editable_by?(Current.user)
    return render json: { error: t("flash.academic_post_not_editable") }, status: :unprocessable_entity unless @post.draft?

    upload = params[:picture]
    errors = ::AcademicPostPictureValidator.errors_for(upload)
    return render json: { errors: errors }, status: :unprocessable_entity if errors.any?

    blob = ActiveStorage::Blob.create_and_upload!(
      io: upload.tempfile,
      filename: upload.original_filename,
      content_type: upload.content_type
    )
    @post.pictures.attach(blob)

    render json: {
      id: blob.id,
      url: rails_blob_path(blob, only_path: true),
      alt: params[:alt].to_s.strip.presence || upload.original_filename.to_s
    }, status: :created
  rescue ActiveRecord::RecordInvalid, ActiveStorage::IntegrityError => error
    blob&.purge
    render json: { errors: [ error.message ] }, status: :unprocessable_entity
  end

  private
    def find_owned_post
      @post = Current.user.academic_posts.find(params[:id])
    end

    def find_accessible_post
      @post = AcademicPost.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @post.accessible_to?(Current.user)
    end

    def post_params
      params.expect(academic_post: [ :title, :body, :lock_version ])
    end
end
