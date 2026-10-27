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

  def destroy_video
    @routine.video.purge_later
    redirect_to edit_admin_routine_path(@routine), notice: t("admin.routines.video_removed"), status: :see_other
  end

  private

  def set_routine
    @routine = Routine.find_by!(slug: params[:id])
  end

  def routine_params
    params.expect(routine: %i[status video])
  end
end
