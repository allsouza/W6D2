require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    conditons = []
    params.each do |k, v|
      conditons << "#{k} = #{v}"
    end
    conditions = conditions.join(" AND ")

    DBConnection.execute(<<-SQL, conditons)
      SELECT
        *
      FROM 
        #{table_name}
      WHERE
        ?
    SQL
  end
end

class SQLObject
    extend Searchable
end
