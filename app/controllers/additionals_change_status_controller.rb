class AdditionalsChangeStatusController < ApplicationController
  before_action :find_issue
  helper :additionals_issues

  def update
    issue_old_status = @issue.status.name
    new_status_id = params[:new_status_id].to_i
    allowed_status = @issue.new_statuses_allowed_to(User.current)
                           .detect { |s| s.id == new_status_id }

    if new_status_id < 1 || @issue.status_id == new_status_id || allowed_status.nil?
      redirect_to(issue_path(@issue))
      return
    end

    @issue.status_id = new_status_id
    @issue.save

    new_journal = @issue.init_journal(User.current)
    new_journal.save!

    last_journal = @issue.journals.visible.order('created_on').last

    JournalDetail.new(property: 'attr',
                      prop_key: 'status',
                      old_value: issue_old_status,
                      value: @issue.status.name,
                      journal: new_journal).save!

    if last_journal.nil?
      redirect_to(issue_path(@issue))
      return
    end

    last_journal = @issue.journals.visible.order('created_on').last
    redirect_to "#{issue_path(@issue)}#change-#{last_journal.id}"
  end

  private

  def find_issue
    @issue = Issue.find_by(id: params[:issue_id].to_i)
    raise Unauthorized unless @issue.visible? && @issue.editable?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end