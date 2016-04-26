class AdsprintsController < ApplicationController
  unloadable

#  before_filter :find_project, :authorize
  before_filter :find_project_by_project_id, :authorize

  def list
    @backlog = SprintsTasks.get_backlog(@project)
    @sprints = Sprints.all_sprints(@project).select {|s| s.name.downcase.match(/release$/).nil? }

    # releases are a versioned backlog that appear on the left side of the interface, rather than with the rest of the sprints on the right
    @releases = Sprints.all_sprints(@project).select {|s| s.name.downcase.match(/release$/).present? }

    # Need to overwrite the @tasks for each sprint to use @project, and not the project the sprint has. (ie Sprint belongs to a Super Project but @project is a sub project)
    # TODO: this is fugly and needs to be cleaner
    @sprints.each {|s| s.tasks = SprintsTasks.get_tasks_by_sprint(@project, s.id) }
    @releases.each {|s| s.tasks = SprintsTasks.get_tasks_by_sprint(@project, s.id) }

    @assignables = {}
    @project.assignable_users.each{ |u| @assignables[u.id] = u.name }
    @project_id = @project.id
    @plugin_path = File.join(Redmine::Utils.relative_url_root, 'plugin_assets', 'agile_dwarf')
    @closed_status = Setting.plugin_agile_dwarf["stclosed"].to_i

    # Calculate the points for each custom_task_field for each user
    @backlog_fields_points = {}
    @backlog.each do |task|
      task.custom_task_fields.each do |field|
        # FIXME: replace with sql join
        type = field.type
        value = field.value
        user = task.assigned_to
        @backlog_fields_points[type] ||= {}
        @backlog_fields_points[type][user] ||= 0
        @backlog_fields_points[type][user] += value || 0
      end
    end

    @sprints_fields_points = {}
    sprints_tasks = @sprints.inject([]) { |s, i| s += i.tasks }
    sprints_tasks.each do |task|
      task.custom_task_fields.each do |field|
        # FIXME: replace with sql join
        type = field.type
        value = field.value
        user = task.assigned_to
        @sprints_fields_points[type] ||= {}
        @sprints_fields_points[type][user] ||= 0
        @sprints_fields_points[type][user] += value || 0
      end
    end

    @releases_fields_points = {}
    releases_tasks = @releases.inject([]) { |s, i| s += i.tasks }
    releases_tasks.each do |task|
      task.custom_task_fields.each do |field|
        # FIXME: replace with sql join
        type = field.type
        value = field.value
        user = task.assigned_to
        @releases_fields_points[type] ||= {}
        @releases_fields_points[type][user] ||= 0
        @releases_fields_points[type][user] += value || 0
      end
    end
  end

  private

  def find_project
    # @project variable must be set before calling the authorize filter
    @project = Project.find(params[:project_id])
  end
end
