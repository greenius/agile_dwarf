class Sprints < Version
  unloadable

  attr_writer :tasks

  validate :start_and_end_dates

  class << self
    def open_sprints(project = nil)
      if project
        all().order('ir_start_date ASC, ir_end_date ASC').where([ "status = 'open' and (project_id IN (?) OR sharing = 'system')", [project.id, project.parent_id].compact ])
      else
        all().order('ir_start_date ASC, ir_end_date ASC').where([ "status = 'open'"])
      end
    end
    def all_sprints(project = nil)
      if project
        all().order('ir_start_date ASC, ir_end_date ASC').where([ "project_id IN (?) OR sharing = 'system'", [project.id, project.parent_id].compact ])
      else
        all().order('ir_start_date ASC, ir_end_date ASC')
      end
    end
  end

  def start_and_end_dates
    errors.add_to_base("Sprint cannot end before it starts") if self.ir_start_date && self.ir_end_date && self.ir_start_date >= self.ir_end_date
  end

  def tasks
    @tasks || SprintsTasks.get_tasks_by_sprint(self.project, self.id)
  end
end
