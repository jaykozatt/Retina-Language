# Classes used to produce the abstract syntax tree
# for Retina Language
#
# Author:    Jonathan Reyes (Alias: Jay Kozatt)
#

############################################################################
##################### Bresenham's Line Algorithm ###########################
############################################################################
def get_line(x0,x1,y0,y1)
  points = []
  steep = ((y1-y0).abs) > ((x1-x0).abs)
  if steep
    x0,y0 = y0,x0
    x1,y1 = y1,x1
  end
  if x0 > x1
    x0,x1 = x1,x0
    y0,y1 = y1,y0
  end
  deltax = x1-x0
  deltay = (y1-y0).abs
  error = (deltax / 2).to_i
  y = y0
  ystep = nil
  if y0 < y1
    ystep = 1
  else
    ystep = -1
  end
  for x in x0..x1
    if steep
      points << {:x => y, :y => x}
    else
      points << {:x => x, :y => y}
    end
    error -= deltay
    if error < 0
      y += ystep
      error += deltax
    end
  end
  return points
end

#######################################################################
######################## Runtime Errors ###############################
#######################################################################

class ContextError < RuntimeError
    def initialize(line=nil, given=nil, expected=nil)
        @line = line
        @expected = expected
        @given = given
    end

    def to_s
        "\n[Context ERROR] Line #{@line}: '#{@expected}' was expected, but '#{@given}' was received."
    end
end

class UndeclaredFunctionError < ContextError
    def initialize(line, func_name)
        @line = line
        @func_name = func_name
    end

    def to_s
        "\n[UndeclaredFunction ERROR] Line #{@line}: function '#{@func_name}' has not been declared."
    end
end

class UndeclaredVariableError < ContextError
    def initialize(tag, line)
        @line = line
        @tag = tag
    end

    def to_s
        "\n[UndeclaredVariable ERROR] Line #{@line}: variable '#{@tag}' has not been declared."
    end
end

class TypeMismatchError < ContextError
    def initialize(line=nil,given=nil,expected=nil,tag=nil)
        super(line,given,expected)
        @tag = tag
    end

    def to_s
        "\n[TypeMismatch ERROR] Line #{@line}: for variable '#{@tag}', '#{@expected}' was expected, but value '#{@given}'' doesn't match."
    end
end

class ReturnTypeError < RuntimeError
    def initialize(foo, given, expected, line)
        @func_name = foo
        @given_type = given
        @expected_type = expected
        @line = line
    end

    def to_s
        "\n[ReturnType ERROR] Line #{@line}: function '#{@func_name}' was expected to return '#{@expected_type}', but it returned '#{@given_type}'."
    end
end

class DivisionByZeroError < RuntimeError
    def initialize(line)
        @line = line
    end

    def to_s
        "\n[DivisionByZero ERROR] Line #{@line}: tried to divide by zero."
    end
end

class InitializationError < RuntimeError
    def initialize(var_name=nil, line=nil)
        @name = var_name
        @line = line
    end

    def to_s
        "\n[Initialization ERROR] Line #{@line}: variable '#{@name}' has not been initialized."
    end
end

class InvalidRangeError < RuntimeError
    def initialize(line)
        @line = line
    end

    def to_s
        "\n[InvalidRange ERROR] Line #{@line}: the range given is not valid."
    end
end

################## Retina Recursion Stack ##################

class RecursionStack
    def initialize()
        @stack = []
    end

    def push(item)
        @stack.push(item)
    end

    def pop()
        @stack.pop()
    end

    def peek()
        @stack.first
    end
end

#####################################################
################ Base Token Classes #################
#####################################################

class AST
    def print_ast(indent="")
        puts("#{indent}#{self.class}:")

        attrs.each do |a|
            a.print_ast indent + "·   " if a.respond_to? :print_ast
        end
    end

    def attrs
        instance_variables.map do |a|
            instance_variable_get(a)
        end
    end

    def build_table(func_table, var_table=nil)
        attrs.each do |a|
            a.build_table(func_table, var_table) if a.respond_to? :build_table
        end
    end

    def check()
        attrs.each do |a|
            a.check if a.respond_to? :check
        end
    end

    # This method is only used to check if a function has a return instruction
    def searchNCheckReturn(fooName,fooType)
        if !fooType.nil?
            attrs.each do |a|
                if a.class.to_s == "Return"
                    raise ReturnTypeError::new(fooName, a.expression.type(), fooType, a.expression.line()) unless a.expression.type() == fooType
                    return true
                end
                return a.searchNCheckReturn(fooName, fooType) if a.respond_to? :searchNCheckReturn
            end
        else
            attrs.each do |a|
                return true if a.class.to_s == "Return"
                return a.searchNCheckReturn(fooName, fooType) if a.respond_to? :searchNCheckReturn
            end
        end
        return false
    end

    def execute()
        attrs.each do |a|
            a.execute if a.respond_to? :execute
        end
    end 
end

######################################################

class CharString < AST
    attr_accessor :charArray, :line

    def initialize(s)
        @charArray = s
        @line = s.line
    end

    def check()
        charArray.check()
    end

    def print_ast(indent="")
        puts("#{indent}String: #{@charArray.item}")
    end

    def type()
        "string"
    end

    def execute()
        result = @charArray.item.to_s[1..(@charArray.item.to_s.length-2)]
    end
end

######################################################

class Item < AST
    attr_accessor :item, :isBoolean, :isNumber, :line
    
    def initialize(item)
        @item = item
        @line = item.line

        @isBoolean = false
        @isNumber = false
    end
    def check()
        item.check()
    end
    def isBoolean()
        return @isBoolean
    end

    def isNumber()
        return @isNumber
    end

    def print_ast(indent="")
        puts("#{indent}#{self.class}: #{@item.item}")
    end
end

######################################################

class Expression < AST
    attr_accessor :item, :line

    def initialize(item)
        @item = item
        @line = item.line
    end

    def isBoolean()
        return item.isBoolean()
    end

    def isNumber()
        return item.isNumber()
    end

    def type()
        return @item.type()
    end

    def execute()
        result = @item.execute()
        raise InitializationError::new(@item.item.item, @line) if result.nil?
        return result
    end
end

#######################################################
################### Generic Classes ###################
#######################################################

class Type < AST
    attr_accessor :type, :line

    def initialize(datatype)
        @type = datatype
        @line = datatype.line
    end

    def print_ast(indent="")
        puts("#{indent}#{self.class}: #{@type.item}")
    end

    def to_s
        "Type: #{@type.item}"
    end
end

#######################################################

class UnaryOperator < Expression

    def initialize(operand)
        super
    end

    def type()
        return @item.type()
    end

    def execute()
        raise InitializationError::new(@item.item.item,@line) if @item.execute.nil?
    end
end

#######################################################

class BinaryOperator < Expression
    attr_accessor :left, :right

    def initialize(lh, rh)
        @left = lh
        @right = rh
        @line = lh.line
    end

    def execute()
        raise InitializationError::new(@left.item.item,@line) if @left.execute.nil?
        raise InitializationError::new(@right.item.item,@line) if @right.execute.nil?
    end

end

class AritBinaryOp < BinaryOperator
    def isNumber()
        check()
        return true
    end

    def isBoolean()
        false
    end

    def check()
        super
        raise ContextError::new(@line,@left.type(),"number") unless @left.isNumber()
        raise ContextError::new(@line,@right.type(),"number") unless @right.isNumber()
    end

    def type()
        "number"
    end
end

class BoolBinaryOp < BinaryOperator
    def isBoolean()
        check()
        return true
    end

    def isNumber()
        false
    end

    def check()
        super
        raise ContextError::new(@line,@left.type(),"boolean") unless @left.isBoolean()
        raise ContextError::new(@line,@right.type(),"boolean") unless @right.isBoolean()
    end

    def type()
        "boolean"
    end
end

class RelationalOp < BoolBinaryOp
    def check()
        raise ContextError::new(@line,@left.type(),"number") unless @left.isNumber()
        raise ContextError::new(@line,@right,type(),"number") unless @right.isNumber()
    end
end 

#######################################################

class List < AST
    attr_accessor :list 

    def initialize(list)
        @list = list
    end

    def print_ast(indent="")
        puts("#{indent}#{self.class}:")
        @list.each { |l| l.print_ast(indent + "·   ") }
    end

    def build_table(func_table, var_table)
        @list.each {|l| l.build_table(func_table,var_table)}
    end

    def check()
        @list.each {|l| l.check()}
    end

    def searchNCheckReturn(fooName, fooType)
        @list.each {|l| l.searchNCheckReturn(fooName, fooType)}
    end

    def execute()
        result = nil
        @list.each {|l| 
            result = l.execute()
            break if result == :return
        }
        return result
    end
end

#########################################################
################## Reserved Structures ##################
#########################################################

class Code < AST
    attr_accessor :items, :func_table, :var_table

    def initialize(items)
        @items = items
        @func_table
        @var_table = []
    end

    def print_ast()
        @items.each do |i|
            i.print_ast();
        end
    end

    def build_table()
        @func_table = FooSymTable.new()
        @func_table.assignName(Identifier.new(Tag.new("foo",nil,nil)))
        @items.each do |i|
            new_table = SymTable.new()
            @var_table += [new_table]
            i.build_table(@func_table, new_table)
        end
    end

    def check()
        @items.each do |i|
            i.check();
        end
    end

    def execute(filename)
        $RecStack = RecursionStack.new()
        $image = Array.new(1001) {Array.new(1001) {0}}
        $cursor = {x: 0, y: 0, angle: 90, isMarking: true}
        @items[@items.length - 1].execute()

        $stdout.flush
        imagefile = filename.dup
        imagefile.slice!("rtn")
        imagefile += "pbm"
        
        File.open(imagefile, "w") do |f|
            puts("\n[SYSTEM] Generando imagen resultante...")
            STDOUT.flush
            f.syswrite("P1\n")
            f.syswrite("1001 1001\n")
            prev_percent = 0
            for y in 0..1000
                for x in 0..1000
                    f.syswrite($image[x][y])
                    f.syswrite(" ")
                end
                f.syswrite("\n")
                percent = (y*100/1001).round
                print("[SYSTEM] "+ percent.to_s + "%\r") if percent % 5 == 0 and percent != prev_percent  
                $stdout.flush
                prev_percent = percent
            end
        end
        puts("[SYSTEM] Listo!")

    end

    def print_scope()
        @var_table.each do |t|
            t.print_scope()
        end
    end
end

#######################################################

class MainBlock < AST
    attr_accessor :block 

    def initialize(block)
        @block = block
    end

    def build_table(func_table,var_table)
        super
        var_table.assignName(Identifier.new(Tag.new("program",nil,nil)))
    end
end

#######################################################

class Block < AST
    attr_accessor :declarations, :instructions

    def initialize(declarations,instructions)
        @declarations = declarations
        @instructions = instructions
    end

    def build_table(func_table, var_table)
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        super(func_table,local_table)
    end

end

#######################################################

class Declaration < AST
    attr_accessor :datatype, :tag, :data

    def initialize(datatype, tag, data)
        @datatype = datatype
        @tag = tag
        @data = data
    end

    def build_table(func_table, var_table)
        var_table.addEntry(@tag, @datatype.type.item)
        super
    end

    def check()
        if !@data.nil? then
            raise ContextError::new(@tag.line, @data.type(), @tag.type()) unless @tag.type()==@data.type() 
        end
    end

    def execute()
        @tag.getTable.update(@tag.item.item, @data.execute()) unless @data.nil?
    end
end

#######################################################

class FunctionDeclare < AST
    attr_accessor :tag, :arguments, :returntype, :instructions

    def initialize(tag, arguments, returntype, instructions)
        @tag = tag
        @arguments = arguments
        @returntype = returntype
        @instructions = instructions
    end

    def build_table(func_table, var_table)
        if @returntype != nil
            type = @returntype.type.item
        else 
            type = nil
        end
        func_table.addEntry(@tag, type, @arguments, @instructions, var_table)
        super
        @tag.build_table(func_table, func_table) # A hotfix for the issue that was associating a "variable table" to a "function tag"
        var_table.assignName(@tag)
        func_table.checkReturn(@tag.item.item)
    end
end

#######################################################

class FunctionCall < AST
    attr_accessor :tag, :parameters

    def initialize(tag, parameters)
        @tag = tag
        @parameters = parameters
        @func_table
    end

    def build_table(func_table,var_table)
        @func_table = func_table
        super
    end

    def line()
        @tag.line
    end

    def fooName()
        @tag.item.item
    end

    def isBoolean()
        return @func_table.getReturnType(fooName) == "boolean"
    end

    def isNumber()
        return @func_table.getReturnType(fooName) == "number"
    end

    def type()
        return @func_table.getReturnType(fooName)
    end

    def check()
        func_name = @tag.item
        raise UndeclaredFunctionError::new(func_name.line, fooName) unless @func_table.contains?(func_name.item)
        @func_table.checkParamType(fooName, @parameters)
    end

    def execute() ##### This execution is half broken. Las llamadas recursivas no funcionan en lo absoluto.
        # (Can't remember if this was fixed)
        local_table = SymTable.new()
        fooName = @tag.item.item
        $RecStack.push(fooName) # Keep track of the current function context
        
        instance = @func_table.table[fooName].dup
        instance[:instructions].build_table(@func_table, local_table)
        instance[:arguments].build_table(@func_table, local_table) unless instance[:arguments].nil?
        instance[:instructions].check()
        i = 0

        instance[:arguments].list.each do |a|
            argi = a.identifier
            arg_name = argi.item.item
            argi.getTable.update(arg_name, @parameters.list[i].execute)
            i += 1
        end unless instance[:arguments].nil?
        
        # Execute each instruction of this function
        instance[:instructions].execute()
        
        # Recover the returned value and clear this context from the stack
        result = @func_table.getReturnValue(fooName)
        $RecStack.pop
        
        return result
    end
end

#######################################################

class RepeatCall < AST
    attr_accessor :times, :instructions

    def initialize(times, instructions)
        @times = times
        @instructions = instructions
    end

    def check()
        raise ContextError::new(@times.line, @times.type, "number") unless @times.isNumber()
        @instructions.check()
    end

    def build_table(func_table,var_table)
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        super(func_table,local_table)
    end

    def execute()
        for i in 0..@times.execute() do
            @instructions.execute()
        end
    end
end

#######################################################

class ForCall < AST
    attr_accessor :iterator, :start, :finish, :factor, :instructions

    def initialize(iterator, start, finish, factor, instructions)
        @iterator = iterator
        @start = start
        @finish = finish
        @factor = factor
        @instructions = instructions        
        @func_table
    end

    def check()
        raise ContextError::new(@start.line, @start.type, "number") unless @start.isNumber()
        raise ContextError::new(@finish.line, @finish.type, "number") unless @finish.isNumber()
        if @factor != nil
            raise ContextError::new(@factor.line, @factor.type, "number") unless @factor.isNumber()
        end
        @instructions.check()
    end

    def build_table(func_table,var_table)
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        local_table.addEntry(@iterator, "number")
        super(func_table,local_table)
    end

    def execute
        varName = @iterator.item.item
        @iterator.getTable.update(varName, (@start.execute).floor)
        raise InvalidRangeError::new(@iterator.line) if (@start.execute).floor > (@finish.execute).floor or @factor.execute <= 0

        while @iterator.getTable.table[varName][:value] <= (@finish.execute()).floor do
            @instructions.execute()
            new_value = @iterator.getTable.table[varName][:value] + @factor.execute()
            @iterator.getTable.update(varName, new_value)
        end
    end
end

#######################################################

class WhileCall < AST
    attr_accessor :condition, :instructions

    def initialize(condition, instructions)
        @condition = condition
        @instructions = instructions
    end

    def check()
        raise ContextError::new(@condition.line, @condition.type, "boolean") unless @condition.isBoolean()
        @instructions.check()
    end

    def build_table(func_table,var_table)
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        @condition.build_table(func_table,var_table) #if @instructions.respond_to? :build_table
        @instructions.build_table(func_table,local_table) if @instructions.respond_to? :build_table
    end

    def execute
        while @condition.execute() do
            @instructions.execute
        end
    end
end

#######################################################

class IfThen < AST
    attr_accessor :condition, :instructions

    def initialize(condition, instructions)
        @condition = condition
        @instructions = instructions
    end

    def check()
        raise ContextError::new(@condition.line, @condition.type, "boolean") unless @condition.isBoolean()
        @instructions.check()
    end

    def build_table(func_table,var_table)
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        @condition.build_table(func_table,var_table) #if @instructions.respond_to? :build_table
        @instructions.build_table(func_table,local_table) if @instructions.respond_to? :build_table
    end

    def execute
        if @condition.execute then
            @instructions.execute
        end
    end
end

#######################################################

class IfElse < AST
    attr_accessor :condition, :ifInstructions, :elseInstructions

    def initialize(condition, instructions1, instructions2)
        @condition = condition
        @ifInstructions = instructions1
        @elseInstructions = instructions2
    end

    def check()
        raise ContextError::new(@condition.line, @condition.type, "boolean") unless @condition.isBoolean()
        @ifInstructions.check()
        @elseInstructions.check()
    end

    def build_table(func_table,var_table)
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        @condition.build_table(func_table,var_table) #if @instructions.respond_to? :build_table
        @ifInstructions.build_table(func_table,local_table) if @ifInstructions.respond_to? :build_table
        local_table = SymTable.new(var_table)
        var_table.addChild(local_table)
        @elseInstructions.build_table(func_table,local_table) if @elseInstructions.respond_to? :build_table
    end

    def execute
        if @condition.execute then
            @ifInstructions.execute
        else
            @elseInstructions.execute
        end
    end
end

#######################################################

class Return < AST
    attr_accessor :expression

    def initialize(e)
        @expression = e
        @func_table
    end

    def build_table(func_table,var_table)
        @func_table = func_table
        super
    end

    def execute()
        # Gets the currently running function's name and prepare to check type
        fooName = $RecStack.peek()
        given = @expression.type()
        expected = @func_table.getReturnType(fooName)

        # Check dynamically that type matches
        unless given == expected
            raise ReturnTypeError::new(fooName,given,expected,@expression.line)
        end
        
        # Get the expression's value and return the result
        value = @expression.execute()
        @func_table.setReturnValue(fooName,value)
        return :return # this flag interrupts further instruction executions for the current function
    end

end

#######################################################

class Assign < AST
    attr_accessor :identifier, :value

    def initialize(identifier, value)
        @identifier = identifier
        @value = value
    end

    def check()
        raise ContextError::new(@value.line, @value.type(), @identifier.type()) unless @value.type() == @identifier.type()
        @value.check()
    end

    def execute()
        @identifier.getTable.update(@identifier.item.item, @value.execute())
    end
end

#######################################################

class Argument < AST
    attr_accessor :type, :identifier

    def initialize(type, identifier)
        @type = type
        @identifier = identifier
    end

    def build_table(func_table, var_table)
        var_table.addEntry(@identifier, @type.type.item)
        super
    end
end

#######################################################

class StdIn < AST
    attr_accessor :input

    def initialize(input)
        @input = input
    end

    def execute()
        varName = @input.item.item
        table = @input.getTable()
        value = $stdin.gets.chomp()
        type = table.getType(varName)

        case type
        when "boolean"
            raise TypeMismatchError::new(@input.line,value,type,varName) if value != "true" && value != "false"
            value = (value == "true")
        when "number"
            raise TypeMismatchError::new(@input.line,value,type,varName) if value.to_f == 0.0 && (value != "0.0"||value != "0")
            value = value.to_f
        end

        table.update(varName, value)
    end
end

#######################################################

class StdOut < AST
    attr_accessor :output

    def initialize(out)
        @output = out
    end

    def execute()
        @output.list.each do |o|
            print(o.execute())
        end
    end
end

class StdOutAndLine < StdOut; 
    def execute()
        @output.list.each do |o|
            puts(o.execute())
        end
    end
end

#######################################################
################ Movement Functions ###################
#######################################################

class NoParamFunction < AST; end

class SingleParamFunction < AST
    def initialize(param)
        @parameter = param
    end

    def check()
        raise ContextError::new(@parameter.line, @parameter.type, "number") unless @parameter.isNumber()
    end
end

class DualParamFunction < AST
    def initialize(param1,param2)
        @param1 = param1
        @param2 = param2
    end

    def check()
        raise ContextError::new(@param1.line, @param1.type, "number") unless @param1.isNumber()
        raise ContextError::new(@param2.line, @param2.type, "number") unless @param2.isNumber()
    end
end

############################################################
################## Bulk Declarations #######################
############################################################

#Basic Tokes for Data
class Number < Item
    def initialize(item)
        super
        @type = "number"
        @isNumber = true
    end
    def type()
        return @type
    end
    def execute()
        return @item.item.to_f
    end
end
class Boolean < Item
    def initialize(item)
        super
        @type = "boolean"
        @isBoolean = true
    end
    def type()
        return @type
    end
    def execute()
        return true if @item.item == "true"
        return false if @item.item == "false" 
    end
end
class Identifier < Item
    attr_accessor :table

    def initialize(item, table=nil)
        super(item)
        @local_table = table
    end

    def build_table(func_table,var_table)
        @local_table = var_table
    end

    def isNumber()
        return ("number" == @local_table.getType(@item.item))
    end

    def isBoolean()
        return ("boolean" == @local_table.getType(@item.item))
    end

    def type()
        return @local_table.getType(@item.item)
    end

    def getTable()
        return @local_table
    end

    def check()
        raise UndeclaredVariableError::new(@item.item,@item.line) unless @local_table.contains?(@item.item)
    end

    def execute()
        return @local_table.getValue(@item.item)
    end
end

#Lists
class ArgumentList < List; end
class DeclarationList < List; end
class InstructionList < List; end
class Parameters < List; end

#Aritmethic Operators
class UnaryMinus < UnaryOperator
    def check()
        raise ContextError::new(@line,@item,"number") unless @item.isNumber()
    end
    def execute()
        super
        return (-1) * @item.execute()
    end
end
class Addition < AritBinaryOp; 
    def execute()
        super
        return @left.execute + @right.execute
    end
end
class Substraction < AritBinaryOp; 
    def execute()
        super
        return @left.execute - @right.execute
    end
end
class Multiplication < AritBinaryOp; 
    def execute
        super
        return @left.execute * @right.execute
    end
end
class WholeDivision < AritBinaryOp; 
    def execute
        super
        raise DivisionByZeroError::new(@right.line) if @right.execute == 0
        return (@left.execute / @right.execute).floor
    end
end
class Modulus < AritBinaryOp; 
    def execute
        super
        raise DivisionByZeroError::new(@right.line) if @right.execute == 0
        return (@left.execute).floor % (@right.execute).floor
    end
end
class ExactDivision < AritBinaryOp; 
    def execute
        super
        raise DivisionByZeroError::new(@right.line) if @right.execute == 0
        return @left.execute / @right.execute
    end
end 
class ExactModulus < AritBinaryOp; 
    def execute
        super
        raise DivisionByZeroError::new(@right.line) if @right.execute == 0
        return @left.execute % @right.execute
    end
end

#Logic Operators
class NegationOp < UnaryOperator
    def check()
        raise ContextError::new(@line,@item,"boolean") unless @item.isBoolean()
    end
    def execute
        super
        !@item.execute
    end
end
class Conjunction < BoolBinaryOp; 
    def execute
        super
        @left.execute and @right.execute
    end
end
class Disjunction < BoolBinaryOp; 
    def execute
        super
        @left.execute or @right.execute
    end
end

#Relational Operators
class Equivalence < BoolBinaryOp; 
    def check() # the emptiness is deliberate
    end
    def execute
        super
        @left.execute == @right.execute
    end
end
class Difference < BoolBinaryOp; 
    def check() # the emptiness is deliberate
    end
    def execute
        super
        @left.execute != @right.execute
    end
end
class EqualGreaterThan < RelationalOp; 
    def execute
        super
        @left.execute >= @right.execute
    end
end
class EqualLessThan < RelationalOp; 
    def execute
        super
        @left.execute <= @right.execute
    end
end
class LessThan < RelationalOp; 
    def execute
        super
        #puts @left.class
        #puts @right.class
        @left.execute < @right.execute
    end
end
class GreaterThan < RelationalOp; 
    def execute
        super
        @left.execute > @right.execute
    end
end

#Generalization
class Condition < Expression; 
    def check()
        raise ContextError::new(@line,@item,"boolean") unless @item.isBoolean()
    end
end

#Movement Functions
class HomeCall < NoParamFunction; 
    def execute
        $cursor[:x], $cursor[:y] = 0,0
    end
end
class OpenEyeCall < NoParamFunction; 
    def execute
        $cursor[:isMarking] = true
    end
end
class CloseEyeCall < NoParamFunction; 
    def execute
        $cursor[:isMarking] = false
    end
end
class ForwardCall < SingleParamFunction; 
    def execute
        x = (@parameter.execute * Math.cos($cursor[:angle]*Math::PI/180)).round
        y = (@parameter.execute * Math.sin($cursor[:angle]*Math::PI/180)).round
        if $cursor[:isMarking] then
            points = get_line($cursor[:x], $cursor[:x]+x, $cursor[:y], $cursor[:y]+y)
            points.each do |p| 
                if p[:x] < 501 and p[:x] > -501 and p[:y] < 501 and p[:y] > -501 then
                    $image[500+p[:x]][500+p[:y]] = 1
                end
            end
        end

        $cursor[:x] += x 
        $cursor[:y] += y

        $cursor[:x] = 500 if $cursor[:x] >= 500
        $cursor[:x] = -500 if $cursor[:x] <= -500
        $cursor[:y] = 500 if $cursor[:y] >= 500
        $cursor[:y] = -500 if $cursor[:y] <= -500
    end
end
class BackwardCall < SingleParamFunction; 
    def execute
        x = (@parameter.execute * Math.cos(($cursor[:angle] + 180)*Math::PI/180)).round
        y = (@parameter.execute * Math.sin(($cursor[:angle] + 180)*Math::PI/180)).round
        if $cursor[:isMarking] then
            points = get_line($cursor[:x], $cursor[:x]+x, $cursor[:y], $cursor[:y]+y)
            points.each do |p| 
                $image[500+p[:x]][500+p[:y]] = 1 if p[:x] < 501 and p[:x] > -501 and p[:y] < 501 and p[:y] > -501
            end
        end
        $cursor[:x] += x 
        $cursor[:y] += y

        $cursor[:x] = 500 if $cursor[:x] > 500
        $cursor[:x] = -500 if $cursor[:x] < -500
        $cursor[:y] = 500 if $cursor[:y] > 500
        $cursor[:y] = -500 if $cursor[:y] < -500
    end
end
class RotatelCall < SingleParamFunction; 
    def execute
        $cursor[:angle] += @parameter.execute
        $cursor[:angle] -= 360 if $cursor[:angle] > 360
    end
end
class RotaterCall < SingleParamFunction; 
    def execute
        $cursor[:angle] -= @parameter.execute
        $cursor[:angle] += 360 if $cursor[:angle] < 0
    end
end
class SetPositionCall < DualParamFunction; 
    def execute
        $cursor[:x], $cursor[:y] = @param1.execute, @param2.execute
    end
end
class ArcCall < DualParamFunction; 
    def execute
        # Save the cursor's current position
        cur_x = $cursor[:x]
        cur_y = $cursor[:y]
        cur_th = $cursor[:angle]

        # Get the parameter values
        degrees = @param1.execute
        radius = @param2.execute

        # Set the starting point for the arc
        ox = (cur_x + radius * Math.cos(cur_th*Math::PI/180)).round
        oy = (cur_y + radius * Math.sin(cur_th*Math::PI/180)).round
        oth = cur_th

        # Draw the arc
        if $cursor[:isMarking] then
            # The idea is to compute the delta angle between pixels, for a given radius
            # And with that, generate a range to be used in a 'for' loop
            pix45 = (Math::PI/4 * radius).floor # number of pixels in 45°
            dth = (Math::PI/4) / pix45 # rate of change for angle (delta theta)
            
            range = (oth..(oth+degrees)).step(dth)

            for th in range do
                x = (cur_x + radius * Math.cos(th*Math::PI/180)).round
                y = (cur_y + radius * Math.sin(th*Math::PI/180)).round
                $image[500+x][500+y] = 1 if (x < 501 and x > -501) and (y < 501 and y > -501)
            end
            $image[500+cur_x][500+cur_y] = 1
        end
    end
end


