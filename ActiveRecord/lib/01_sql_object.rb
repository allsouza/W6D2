require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  # @table_name = nil not needed
  # @columns = nil
  def self.columns
    @columns ||= (DBConnection.execute2("SELECT * FROM #{table_name}")).first.map { |ele| ele.to_sym}
  end

  def self.finalize!
    columns.each do |column|
        self.define_method(column) do
          attributes[column]
        end
        self.define_method(column.to_s+"=") do |arg|
          attributes[column] = arg
        end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    parse_all(DBConnection.execute("SELECT #{table_name}.* FROM #{table_name}"))
  end

  def self.parse_all(results)
    results.map{ |result| self.new(result)}
  end

  def self.find(id)
    result = (DBConnection.execute("SELECT #{table_name}.* FROM #{table_name} WHERE id = #{id}").first)
    result.nil? ? nil : self.new(result)
  end

  def initialize(params = {})
    columns = self.class.columns
    params.each do |k, v|
      raise "unknown attribute '#{k}'" if !columns.include?(k.to_sym)
      k = (k.to_s+"=").to_sym
      send(k, v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.attributes.values
  end

  def insert
    col_names = self.class.columns[1..-1].join(", ")
    my_values = self.attribute_values
    question_marks = Array.new(self.attributes.length, '?').join(', ')
    DBConnection.execute(<<-SQL, *my_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
   
    self.id = DBConnection.last_insert_row_id
  end

  def update
    my_values = self.attributes.to_a
    id = my_values.shift[1]
    my_values = my_values.to_h
    setter = ""
    my_values.each { |k,v| setter += "#{k} = ?, "}
    DBConnection.execute(<<-SQL, *my_values.values)
      UPDATE
        #{self.class.table_name}
      SET
        #{setter[0...-2]}
      WHERE
        id = #{id}
    SQL
  end

  def save
    self.id.nil? ? self.insert : self.update
  end
end
