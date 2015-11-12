class SprintsTasks < Issue
  unloadable

  acts_as_list :column => "ir_position"
  has_many :custom_task_fields, dependent: :destroy, order: 'type_id ASC'

  after_create :create_custom_task_fields

  ORDER = 'case when issues.ir_position is null then 1 else 0 end ASC, case when issues.ir_position is NULL then issues.id else issues.ir_position end ASC'

  def self.get_tasks_by_status(project, status, sprint, user)
    cond = ["issues.project_id = ? and status_id = ?", project.id, status]
    if sprint == 'null'
      cond[0] += ' and fixed_version_id is null'
    elsif sprint
      cond[0] += ' and fixed_version_id = ?'
      cond << sprint
    end
    if user
      cond[0] += ' and assigned_to_id = ?'
      user = User.current.id if user == 'current'
      cond << user
    end
#    tasks = SprintsTasks.find(:all, :select => 'issues.*, sum(hours) as spent', :order => SprintsTasks::ORDER, :conditions => cond, :group => "issues.id", :joins => [:status], :joins => "left join time_entries ON time_entries.issue_id = issues.id", :include => [:assigned_to, :custom_task_fields])
    tasks = SprintsTasks.all().select('issues.*, sum(hours) as spent').order(SprintsTasks::ORDER).where(cond).group("issues.id").joins([:status]).joins("left join time_entries ON time_entries.issue_id = issues.id").includes([:assigned_to, :custom_task_fields])

    filter_out_user_stories_with_children tasks
  end

  def self.get_tasks_by_sprint(project, sprint)
    cond = ["is_closed = ?", false]
    if project.present?
      cond[0] += ' and project_id IN (?)'
      cond << [project.id, project.parent_id].compact
    end

    if sprint.present?
      if sprint == 'null'
        cond[0] += ' and fixed_version_id is null'
      else
        cond[0] += ' and fixed_version_id = ?'
        cond << sprint
      end
    end

#    tasks = SprintsTasks.find(:all, :select => 'issues.*, trackers.name AS t_name', :order => SprintsTasks::ORDER, :conditions => cond, :joins => :status, :joins => "left join issue_statuses on issue_statuses.id = status_id left join trackers on trackers.id = tracker_id", :include => [:assigned_to, :custom_task_fields])
    tasks = SprintsTasks.all().select('issues.*, trackers.name AS t_name').order(SprintsTasks::ORDER).where(cond).joins(:status).joins("left join issue_statuses on issue_statuses.id = status_id left join trackers on trackers.id = tracker_id").includes([:assigned_to, :custom_task_fields])
    filter_out_user_stories_with_children tasks
  end

  def self.filter_out_user_stories_with_children(tasks)
    # if the task is a user story then only display it if it has no child issues.
    # if it does then we schedule the child issues, not the user story itself
    userstory_tracker = Tracker.find_by_name("UserStory")
    if userstory_tracker
      tasks.select do |t|
        if t.tracker_id == userstory_tracker.id
          t.descendants.empty?
        else
          true
        end
      end
    else
      tasks
    end
  end

  def self.get_backlog(project = nil)
    SprintsTasks.get_tasks_by_sprint(project, 'null')
  end

  def move_after(prev_id)
    remove_from_list

    if prev_id.to_s == ''
      prev = nil
    else
      prev = SprintsTasks.find(prev_id)
    end

    if prev.blank?
      insert_at
      move_to_top
    elsif !prev.in_list?
      insert_at
      move_to_bottom
    else
      insert_at(prev.ir_position + 1)
    end
  end

  def update_and_position!(params)
    attribs = params.select{|k,v| k != 'id' && k != 'project_id' && SprintsTasks.column_names.include?(k) }
    attribs = Hash[*attribs.flatten]
    if params[:prev]
      move_after(params[:prev])
    end
    self.init_journal(User.current)
    update_attributes attribs
  end

  private
    def create_custom_task_fields
      CustomTaskFieldType.all.each do |type|
        ctf = CustomTaskField.new
        ctf.sprints_tasks = self
        type.custom_task_fields << ctf
      end
    end
end
