class RevisionMailer < ApplicationMailer
  # To each maintainer and admin when a contributor submits a change
  def submitted(revision, reviewer)
    @revision = revision
    @reviewer = reviewer
    mail_to reviewer, ".subject"
  end

  # To the contributor when their change is published, sent back or rejected
  def decided(revision)
    @revision = revision
    I18n.with_locale(revision.author.locale) do
      mail(to: revision.author.email_address, subject: t(".subject.#{revision.status}", movement: revision.movement.name_zh))
    end
  end
end
