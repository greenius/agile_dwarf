class Sprints < Version
  unloadable

  attr_writer :tasks

  validate :start_and_end_dates

  class << self
    def open_sprints(project = nil)
      unless project.nil?
        self.rolled_up_versions(project).order('ir_start_date ASC, ir_end_date ASC').where([ "versions.status = 'open'"])
      else
        all().order('ir_start_date ASC, ir_end_date ASC').where([ "status = 'open'"])
      end
    end
    def all_sprints(project = nil)
      unless project.nil?
        self.rolled_up_versions(project).order('ir_start_date ASC, ir_end_date ASC')
      else
        all().order('ir_start_date ASC, ir_end_date ASC')
      end
    end
    def rolled_up_versions(project)
      logger.debug "Project lft=#{project.lft}, rft=#{project.rgt}"
      @rolled_up_versions =
        Sprints.
        joins(:project).
        where("#{Project.table_name}.lft >= :lft AND #{Project.table_name}.rgt <= :rgt AND #{Project.table_name}.status <> :status", { lft: project.lft, rgt: project.rgt, status: Project::STATUS_ARCHIVED })
    end
  end
  
  def start_and_end_dates
    errors.add_to_base("Sprint cannot end before it starts") if self.ir_start_date && self.ir_end_date && self.ir_start_date >= self.ir_end_date
  end

  def tasks
    SprintsTasks.get_tasks_by_sprint(self.project, self.id)
  end



end
