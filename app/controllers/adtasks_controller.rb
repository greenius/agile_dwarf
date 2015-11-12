class AdtasksController < ApplicationController
  unloadable

  before_filter :find_project, :authorize

  def list
    # data for filters
    @sprints = Sprints.open_sprints(@project)
    @project_id = @project.id
    @assignables = @project.assignable_users
    @assignables_list = {}
    @project.assignable_users.each{|u| @assignables_list[u.id] = u.name}
    # Support Assign to nobody
    @assignables_list[""] = ""

    # filter values
    @selected = params[:sprint] || (@sprints[0].nil? ? 'all' : @sprints[0].id.to_s)
    case @selected
      when 'all'
        sprint = nil
      when 'none'
        sprint = 'null'
      else
        sprint = @selected
    end
    user = @user = params[:user] || 'current'
    user = nil if @user == 'all'

    @plugin_path = File.join(Redmine::Utils.relative_url_root, 'plugin_assets', 'agile_dwarf')
    status_ids = []
    colcount = Setting.plugin_agile_dwarf['stcolumncount'].to_i
    for i in 1 .. colcount
      status_ids << Setting.plugin_agile_dwarf[('stcolumn' + i.to_s)].to_i
    end
    @statuses = {}
#    IssueStatus.find_all_by_id(status_ids).each {|x| @statuses[x.id] = x.name}
    IssueStatus.find_by(id: status_ids).each {|x| @statuses[x.id] = x.name}
    @columns = []
    for i in 0 .. colcount - 1
      tasks = SprintsTasks.get_tasks_by_status(@project, status_ids[i], sprint, user)
      points = {}
      tasks.each do |task|
        task.custom_task_fields.each do |field|
          # FIXME: replace with sql join
          type = field.type
          value = field.value
          user = task.assigned_to
          points[type] ||= {}
          points[type][user] ||= 0
          points[type][user] += value || 0
        end
      end
      column = { tasks: tasks, id: status_ids[i], points: points }
      @columns << column
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end
