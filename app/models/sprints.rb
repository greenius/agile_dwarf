class Sprints < Version
  unloadable

  attr_writer :tasks

  validate :start_and_end_dates

  class << self
    def open_sprints(project = nil)
      if project
        # all().order('ir_start_date ASC, ir_end_date ASC').where([ "status = 'open' and (project_id IN (?) OR sharing = 'system')", [project.id, project.parent_id].compact ])
        # all().order('ir_start_date ASC, ir_end_date ASC').where([ "status = 'open' AND project_id IN (?)", project.rolled_up_versions])
        self.rolled_up_versions(project).order('ir_start_date ASC, ir_end_date ASC').where([ "versions.status = 'open'"])
      else
        all().order('ir_start_date ASC, ir_end_date ASC').where([ "status = 'open'"])
      end
    end
    def all_sprints(project = nil)
      if project
        # all().order('ir_start_date ASC, ir_end_date ASC').where([ "project_id IN (?) OR sharing = 'system'", [project.id, project.parent_id].compact ])
        self.rolled_up_versions(project).order('ir_start_date ASC, ir_end_date ASC')
      else
        all().order('ir_start_date ASC, ir_end_date ASC')
      end
    end
    def rolled_up_versions(project)
      @rolled_up_versions ||=
        Sprints.
        joins(:project).
        where("#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ? AND #{Project.table_name}.status <> ?", project.lft, project.rgt, Project::STATUS_ARCHIVED)
    end
  end
  
  def start_and_end_dates
    errors.add_to_base("Sprint cannot end before it starts") if self.ir_start_date && self.ir_end_date && self.ir_start_date >= self.ir_end_date
  end

  def tasks
    @tasks || SprintsTasks.get_tasks_by_sprint(self.project, self.id)
  end



end
