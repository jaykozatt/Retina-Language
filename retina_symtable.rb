# -*- coding: utf-8 -*-

# Symbols table
# Holds the data regarding variable names, their values, and
# function names, their arguments, instructions, and return type.
# May also be queried for a function call's result.
#
# Author: Jonathan Reyes (Alias: Jay Kozatt)

class SymTableError < RuntimeError; end

class RedefineVarError < SymTableError
	def initialize(tag, line)
		@tag = tag
		@line = line
	end

	def to_s
		"\n[Redefine ERROR] Line #{@line}: tried declaring '#{@tag}' twice in the same scope."
	end
end

class RedefineFooError < RedefineVarError; 
	def to_s
		"\n[Redefine ERROR] Line #{@line}: tried defining function '#{@tag}' when another definition was already given."
	end
end

class DataTypeError < SymTableError
	def initialize(proper_type, given_type, line)
		@proper_type = proper_type
		@given_type = given_type
		@line = line
	end

	def to_s
		"\n[Datatype ERROR] Line #{@line}: '#{@proper_type}' was expected, but a value of type '#{@given_type}' was given."
	end
end

class UnexpectedParamError < SymTableError
	def initialize(line)
		@line = line
	end

	def to_s
		"\n[UnexpectedParam ERROR] Line #{@line}: unexpected number of parameters was given."
	end
end

### I reckon this ended up not being needed.

# class ExpectedReturnError < SymTableError
# 	def initialize(foo)
# 		@func_name = foo
# 	end

# 	def to_s
# 		"\n[ExpectedReturn ERROR] function '#{@func_name}' expected to return '#{@type}', but nothing was."
# 	end
# end

# class UnexpectedReturnError < SymTableError
# 	def initialize(foo)
# 		@func_name = foo
# 	end

# 	def to_s
# 		"\n[UnexpectedReturn ERROR] function '#{@func_name}' didn't expect to return anything, but something was given.\nThis is broken right now..."
# 	end
# end

class SymTable
	attr_accessor :parent, :table

	def to_s
		puts "---- Table ----"
		@table.each {|k,v| puts "#{k} --> #{v}" }
		puts "####### Child #######"
		@child.each {|c| puts c}
	end

	def initialize(parent=nil)
		@parent = parent
		@child = []
		@table = {}
		@name = nil
	end

	def addEntry(tag, type=nil, value=nil)
		raise RedefineVarError::new(tag.item.item, tag.line) if @table.has_key?(tag.item.item)
		@table[tag.item.item] = {type: type, value: value}
	end

	def addChild(child)
		@child += [child]
	end

	def assignName(tag)
		@name = tag.item.item
	end

	def getValue(tag) 
		if @table[tag].nil? and !@parent.nil? then
			return @parent.getValue(tag)
		elsif @table[tag].nil? and @parent.nil?
			puts("Bug: ¿Tablas no contienen el valor de '#{tag}'?")
			return nil
		elsif !@table[tag].nil?
			return @table[tag][:value]
		end
	end

	def update(tag, value)
		if !@table[tag].nil?
			@table[tag][:value] = value
		else
			@parent.update(tag, value)
		end
	end

	def contains?(tag)
		if parent.nil? then 
			return @table.has_key?(tag)
		else 
			return (@table.has_key?(tag) or @parent.contains?(tag))
		end
	end

	def getType(tag)
		if @table.has_key?(tag) then
			return @table[tag][:type]
		elsif !@parent.nil? then
			return @parent.getType(tag) if @parent.contains?(tag)
		end
		return "none"
	end

	def print_scope(indent="")
		puts("#{indent}Alcance _#{@name}:") unless @name.nil?
		puts("#{indent}Sub_Alcance:") if @name.nil?
		puts("#{indent}·   Variables:")
		puts("#{indent}·   ·   Ninguna") if @table.empty? 

		@table.each do |tag, values|
			puts("#{indent}·   ·   #{tag} : #{values[:type]}")
		end

		@child.each do |c|
			c.print_scope(indent + "·   ") if c.respond_to? :print_scope
		end
	end
end

class FooSymTable < SymTable
	def addEntry(tag, type=nil, arguments=nil, instructions=nil, local_table=nil, return_value=nil)
		raise RedefineFooError::new(tag.item.item, tag.line) if @table.has_key?(tag.item.item)
		@table[tag.item.item] = {type: type, arguments: arguments, instructions: instructions, vartable: local_table, return_value: return_value}
	end

	def checkParamType(fooName, param)
		unless @table[fooName][:arguments].nil? then
			if @table[fooName][:arguments].list.length == param.list.length then
				i = 0
				param.list.each do |p|
					raise DataTypeError::new(@table[fooName][:arguments].list[i].identifier.type(),
											 p.type(),p.line) unless @table[fooName][:arguments].list[i].identifier.type() == p.type()
					i += 1
				end
			else
				raise UnexpectedParamError::new(param.list[0].line)
			end
		end
	end

	# This was not needed
	# def checkReturn(fooName)
	# 	existsReturn = false
	# 	if !@table[fooName][:type].nil? then
	# 		#existsReturn = @table[fooName][:instructions].searchNCheckReturn(fooName, @table[fooName][:type])
	# 		#raise ExpectedReturnError::new(fooName) unless existsReturn
	# 	else
	# 		#puts(@table[fooName][:instructions].searchNCheckReturn(fooName, @table[fooName][:type]).to_s)
	# 		#raise UnexpectedReturnError::new(fooName) if @table[fooName][:instructions].searchNCheckReturn(fooName, @table[fooName][:type])	
	# 	end
	# end

	def getReturnType(fooName)
		@table[fooName][:type]
	end

	def setReturnValue(fooName,value)
		@table[fooName][:return_value] = value
	end

	def getReturnValue(fooName)
		@table[fooName][:return_value]
	end
end


