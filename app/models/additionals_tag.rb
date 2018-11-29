class AdditionalsTag
  TAG_TABLE_NAME = RedmineCrm::Tag.table_name
  TAGGING_TABLE_NAME = RedmineCrm::Tagging.table_name
  PROJECT_TABLE_NAME = Project.table_name

  def self.get_available_tags(klass, options = {}, permission = nil)
    scope = RedmineCrm::Tag.where({})
    scope = scope.where("#{PROJECT_TABLE_NAME}.id = ?", options[:project]) if options[:project]
    scope = scope.where(tag_access(permission)) if permission.present?
    scope = scope.where("LOWER(#{TAG_TABLE_NAME}.name) LIKE ?", "%#{options[:name_like].downcase}%") if options[:name_like]
    scope = scope.where("#{TAG_TABLE_NAME}.name=?", options[:name]) if options[:name]
    scope = scope.where("#{TAGGING_TABLE_NAME}.taggable_id!=?", options[:exclude_id]) if options[:exclude_id]
    scope = scope.where(options[:where_field] => options[:where_value]) if options[:where_field].present? && options[:where_value]

    scope = scope.select("#{TAG_TABLE_NAME}.*, COUNT(DISTINCT #{TAGGING_TABLE_NAME}.taggable_id) AS count")
    scope = scope.joins(tag_joins(klass, options))
    scope = scope.group("#{TAG_TABLE_NAME}.id, #{TAG_TABLE_NAME}.name").having('COUNT(*) > 0')
    scope = scope.order("#{TAG_TABLE_NAME}.name")
    scope
  end

  def self.tag_joins(klass, options = {})
    table_name = klass.table_name

    joins = ["JOIN #{TAGGING_TABLE_NAME} ON #{TAGGING_TABLE_NAME}.tag_id = #{TAG_TABLE_NAME}.id"]
    joins << "JOIN #{table_name} " \
             "ON #{table_name}.id = #{TAGGING_TABLE_NAME}.taggable_id AND #{TAGGING_TABLE_NAME}.taggable_type = '#{klass}'"

    if options[:project] || !options[:without_projects]
      joins << "JOIN #{PROJECT_TABLE_NAME} ON #{table_name}.project_id = #{PROJECT_TABLE_NAME}.id"
    end

    joins
  end

  def self.tag_access(permission)
    cond = ''
    projects_allowed = if permission.nil?
                         Project.visible.pluck(:id)
                       else
                         Project.where(Project.allowed_to_condition(User.current, permission)).pluck(:id)
                       end
    cond << "#{PROJECT_TABLE_NAME}.id IN (#{projects_allowed.join(',')})" unless projects_allowed.empty?
    cond
  end

  def self.remove_unused_tags
    unused = RedmineCrm::Tag.find_by_sql(<<-SQL)
      SELECT * FROM tags WHERE id NOT IN (
        SELECT DISTINCT tag_id FROM taggings
      )
    SQL
    unused.each(&:destroy)
  end

  def self.sql_for_tags_field(klass, operator, value)
    compare   = operator.eql?('=') ? 'IN' : 'NOT IN'
    ids_list  = klass.tagged_with(value).collect(&:id).push(0).join(',')
    "( #{klass.table_name}.id #{compare} (#{ids_list}) ) "
  end
end
