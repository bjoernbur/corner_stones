require 'corner_stones/table/selectable_rows'
require 'corner_stones/table/deletable_rows'
require 'corner_stones/table/whitespace_filter'

module CornerStones

  class Table

    class MissingRowError < StandardError; end

    include Capybara::DSL

    def initialize(scope, options = {})
      @scope = scope
      @data_selector = options.fetch(:data_selector) { 'td' }
      @options = options
    end

    def row(options)
      rows.detect { |row|
        identity = row.select { |key, value| options.has_key?(key) }
        identity == options
      } or raise MissingRowError, "no row with '#{options.inspect}'\n\ngot:#{rows}"
    end

    def rows
      within @scope do
        all('tbody tr').map do |row|
          @header_index = 0
          attributes_for_row(row)
        end
      end
    end

    def headers
      @options[:headers] || detect_table_headers
    end

    def detect_table_headers
      all('thead th').map(&:text)
    end

    def attributes_for_row(row)
      row_data = {}
      headers.each.with_index.with_object(row_data) do |(header, index), row_data|
        augment_row_with_cell(row_data, row, index, header)
      end
      row_data['Row-Element'] = row
      row_data
    end

    def augment_row_with_cell(row_data, row, index, header)
      data = row.all(@data_selector)
      cell = data[index]
      unless cell.nil?
        if @header_index.nil?
          row_data[header] = cell.text
        else
          row_data[headers[@header_index]] = cell.text
          @header_index += cell[:colspan].nil? ? 1 : cell[:colspan].to_i
        end
      end
    end

    def value_for_cell(cell)
      cell.text unless cell.nil?
    end
  end

end
