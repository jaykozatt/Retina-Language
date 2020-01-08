# -*- coding: utf-8 -*-

#
# Lexer: parses each word input and turns them into tokens
# 		 ready to be processed by the grammatical parser.
#
# Author: Jonathan Reyes (Alias: Jay Kozatt)
# 

class Token
  attr_reader(:item, :line, :column)

  
  def initialize(item, line, column)
    @item = item
    @line = line
    @column = column
  end

  def to_s
    "Line #{line}, column #{column}: #{self.class} \'#{item}\'"
  end

  def check
  end

end

$temp = nil

$tokens = {
    CharacterString:          /\A\"[[^\"\n\\]]*\"/,
  	Digit:                    /\A0*([0-9]+(?:\.[0-9]+)?)/,
    #Boolean
  	TrueBoolean:              /\A(true)(?=\s|;|,|\))/,
    FalseBoolean:             /\A(false)(?=\s|;|,|\))/,
    #Comparator
  	Equivalent: 	          /\A(==)/,
    Different:                /\A(\/=)/,
    EqualOrGreater:           /\A(>=)/,
    EqualOrLess:              /\A(<=)/,
    Less:                     /\A(<)/,
    Greater:                  /\A(>)/,
    #Sign
    PuntoComa:                /\A(;)/,
    Comma:                    /\A(,)/,
    OpenBracket:              /\A(\()/,
    CloseBracket:             /\A(\))/,
    Arrow:                    /\A(\->)/,
    Equal:                    /\A(=)/,
    #Aritmethic
  	Plus: 	                  /\A(\+)/,
    Minus:                    /\A(\-)/,
    Asterisk:                 /\A(\*)/,
    Slash:                    /\A(\/)/,
    Percent:                  /\A(%)/,
    Div:                      /\A(div)(?=\s)/,
    Mod:                      /\A(mod)(?=\s)/,
    #Logic
  	Not:                      /\A(not)(?=\s)/,
    And:                      /\A(and)(?=\s)/,
    Or:                       /\A(or)(?=\s)/,
    #ReservedWord
  	Program:	              /\A(program)(?=\s)/,
    With:                     /\A(with)(?=\s)/,
    Do:                       /\A(do)(?=\s)/,
    Repeat:                   /\A(repeat)(?=\s)/,
    While: 					  /\A(while)(?=\s)/,
    For:                      /\A(for)(?=\s)/,
    From:                     /\A(from)(?=\s)/,
    To:                       /\A(to)(?=\s)/,
    By:                       /\A(by)(?=\s)/,
    Begin:                    /\A(begin)(?=\s)/,
    End:                      /\A(end)(?=\s|;)/,
    Func:                     /\A(func)(?=\s)/,
    Read:                     /\A(read)(?=\s)/,
    Write:                    /\A(write)(?=(\s|\())/,
    Writeln:                  /\A(writeln)(?=(\s|\())/,
    If:                       /\A(if)(?=\s)/,
    Then:                     /\A(then)(?=\s)/,
    Else:                     /\A(else)(?=\s)/,
    Times:                    /\A(times)(?=\s)/,
    ReturnToken: 			  /\A(return)(?=\s)/, 
    #Movement Functions
    Home: 					  /\A(home)(?=\()/,
    OpenEye: 				  /\A(openeye)(?=\()/,
    CloseEye: 				  /\A(closeeye)(?=\()/,
    Forward: 				  /\A(forward)(?=\()/,
    Backward: 				  /\A(backward)(?=\()/,
    Rotatel: 				  /\A(rotatel)(?=\()/,
    Rotater: 				  /\A(rotater)(?=\()/,
    SetPosition: 			  /\A(setposition)(?=\()/,
    Arc: 					  /\A(arc)(?=\()/,
    #DataType
    StringType:               /\A(string)(?=\s)/,
    NumberType:               /\A(number)(?=\s)/,
    BooleanType:              /\A(boolean)(?=\s)/,
    #Identifier
    Tag:                      /\A([a-z]\w*)/  
}

class LexicographicError < RuntimeError
  def initialize(item,line,column)
    @item = item
    @line = line
    @column = column
  end

  def to_s
    "\n[Lexeme ERROR]: Line #{@line}, column #{@column}: unknown lexeme \'#{@item}\'"
  end
end

class CharacterString < Token;
  def to_s
    "Line #{@line}, column #{@column}: string #{@item}"
  end
end

class Digit < Token; 
  def to_i
    @item.to_i
  end

  def to_s
    "Line #{@line}, column #{@column}: number \"#{@item}\""
  end
end

class ReservedWord < Token;
  def to_s
    "Line #{@line}, column #{@column}: reserved word \"#{@item}\""
  end
end

class PredefinedFunction < Token
  def to_s
  	"Line #{@line}, column #{@column}: predefined function \"#{@item}\""
  end
end

class Bool < Token;
  def to_b
    @item.to_b
  end

  def to_s
    "Line #{@line}, column #{@column}: boolean \"#{@item}\""
  end
end

class Tag < Token; 
  def to_s
    "Line #{@line}, column #{@column}: identifier \"#{@item}\""
  end
end

class AritmethicOperator < Token; 
  def to_s
    "Line #{@line}, column #{@column}: aritmethic operator \"#{@item}\""
  end
end

class LogicOperator < Token; 
  def to_s
    "Line #{@line}, column #{@column}: logic operator \"#{@item}\""
  end
end

class Comparator < Token; 
  def to_s
    "Line #{@line}, column #{@column}: relational operator \"#{@item}\""
  end
end

class DataType < Token; 
  def to_s
    "Line #{@line}, column #{@column}: data type \"#{@item}\""
  end
end

class Sign < Token; 
  def to_s
    "Line #{@line}, column #{@column}: sign \"#{@item}\""
  end
end

class TrueBoolean < Bool; end
class FalseBoolean < Bool; end

class PuntoComa < Sign; end
class Comma < Sign; end
class OpenBracket < Sign; end
class CloseBracket < Sign; end
class Arrow < Sign; end
class Equal < Sign; end

class Plus < AritmethicOperator; end
class Minus < AritmethicOperator; end
class Asterisk < AritmethicOperator; end
class Slash < AritmethicOperator; end
class Percent < AritmethicOperator; end
class Div < AritmethicOperator; end
class Mod < AritmethicOperator; end

class Not < LogicOperator; end
class And < LogicOperator; end
class Or < LogicOperator; end

class Equivalent < Comparator; end
class Different < Comparator; end
class EqualOrGreater < Comparator; end
class EqualOrLess < Comparator; end
class Less < Comparator; end
class Greater < Comparator; end

class Program < ReservedWord; end
class With < ReservedWord; end
class Do < ReservedWord; end
class Repeat < ReservedWord; end
class While < ReservedWord; end
class For < ReservedWord; end
class From < ReservedWord; end
class To < ReservedWord; end
class By < ReservedWord; end
class Begin < ReservedWord; end
class End < ReservedWord; end
class Func < ReservedWord; end
class Write < ReservedWord; end
class Read < ReservedWord; end
class Writeln < ReservedWord; end
class If < ReservedWord; end
class Then < ReservedWord; end
class Else < ReservedWord; end
class Times < ReservedWord; end
class ReturnToken < ReservedWord; end

class Home < PredefinedFunction; end
class OpenEye < PredefinedFunction; end
class CloseEye < PredefinedFunction; end
class Forward < PredefinedFunction; end
class Backward < PredefinedFunction; end
class Rotatel < PredefinedFunction; end
class Rotater < PredefinedFunction; end
class SetPosition < PredefinedFunction; end
class Arc < PredefinedFunction; end

class StringType < DataType; end
class NumberType < DataType; end
class BooleanType < DataType; end

class Lexer
  attr_reader(:tokens,:unknown,:line,:column)

  def initialize(input)
    @tokens = []
    @unknown = []
    @input = input
    @line = 1
    @column = 1
  end

  def catch_lexeme
    # Return nil, if there is no input
    if @input.empty?
      return nil;
    end

    # Ignore every white space and comment at the begining of string, and assign string following after match to input variable.
    if @input =~ /\A(\s|#.*\n)*/
      @input = $'
    end

    # Count the number of lines ignored
    $temp = $&
    while $temp =~ /\A.*\n/
      @line += 1
      @column = 1
      $temp = $'
    end

    # Count amount of blank space in line before next token
    @column += $temp.length

    # Empty the string buffer 
    $temp = nil

    # Local variable initialize with error, if all regex don't succeed
    class_to_be_instanciated = LexicographicError
    # For every key and value, check if the input match with the actual regex
    $tokens.each do |k,v|
      if @input =~ v
        $temp = $&
        
        # Taking advantage with the reflexivity and introspection of the
        # language is nice
        class_to_be_instanciated = Object::const_get(k)
        break
      end
    end

    # If a blank space was ignored and reached end of file, just end processing loop
    if @input.empty?
      return false
    end
    

    # Raise errors found
    if $temp.nil? and class_to_be_instanciated.eql? LexicographicError
      @input =~ /\A\S(?=\s)/
      @unknown << LexicographicError.new($&,@line,@column)
      @input = @input[$&.length..@input.length-1]
      return @unknown[-1]
    end
    # Append token found to the token list
    @tokens << class_to_be_instanciated.new($temp,@line,@column)
    # Update column position
    @column += $temp.length
    # Update input
    @input = @input[$temp.length..@input.length-1]
    # Return token found
    return @tokens[-1]
  end
end