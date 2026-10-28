class Admin::RoutinesController < Admin::BaseController
  before_action :set_routine, except: :index

  def index
    @routines = Routine.ordered.includes(:movements, video_attachment: :blob)
  end

  def edit
  end

  def update
    @routine.assign_attributes(routine_params)
    if @routine.save
      redirect_to admin_routines_path, notice: t("admin.routines.saved", name: @routine.name_zh)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # Timing editor: play the video and stamp where each movement starts
  def timings
    @movements = @routine.movements.to_a
  end

  def update_timings
    timings = params.expect(timings: [ :finish, { starts: {} } ])
    if @routine.retime(timings[:starts].to_h, timings[:finish])
      redirect_to timings_admin_routine_path(@routine), notice: t("admin.routines.timings_saved", name: @routine.name_zh)
    else
      @movements = @routine.movements.to_a
      @starts, @finish = timings[:starts].to_h, timings[:finish]
      render :timings, status: :unprocessable_entity
    end
  end

  def destroy_video
    @routine.video.purge_later
    redirect_to edit_admin_routine_path(@routine), notice: t("admin.routines.video_removed"), status: :see_other
  end

  private

  def set_routine
    @routine = Routine.find_by!(slug: params[:id])
  end

  def routine_params
    params.expect(routine: %i[status video youtube_url video_title video_author video_author_url])
  end
end
