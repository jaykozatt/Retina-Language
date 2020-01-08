# Grammar file for Retina Language. 
# Used in conjunction with Racc tool to produce the parser for the language
#
# Author:  Jonathan Reyes  (Alias: Jay Kozatt)
#

class Parser

    token 'charArray' 'digit' 'true' 'false' ';' ',' '(' ')' '->' 
          '=' '+' '-' '*' '/' UMINUS '%' 'div' 'mod' 'not' 'and' 
          'or' '==' '/=' '>=' '<=' '<' '>' 'program' 'with' 'do'
          'repeat' 'for' 'from' 'to' 'by' 'begin' 'end' 'func' 
          'read' 'write' 'writeln' 'if' 'then' 'else' 'times' 
          'string' 'number' 'boolean' 'identifier'

  #Stating the precedence of every operator from highest to lowest
    prechigh
        nonassoc UMINUS 'not'
        left '*' '/' 'div' 'and'
        left '%' 'mod'
        left '+' '-' 'or'
        left '<' '>' '<=' '>='
        left '==' '/=' 
    preclow

  #Pairing each token to it's regex defined class
    convert
        'charArray'   'CharacterString'
        'digit'       'Digit'

        'true'        'TrueBoolean'
        'false'       'FalseBoolean'

        ';'           'PuntoComa'
        ','           'Comma'
        '('           'OpenBracket'
        ')'           'CloseBracket'
        '->'          'Arrow'
        '='           'Equal'

        '+'           'Plus'
        '-'           'Minus'
        '*'           'Asterisk'
        '/'           'Slash'
        '%'           'Percent'
        'div'         'Div'
        'mod'         'Mod'

        'not'         'Not'
        'and'         'And'
        'or'          'Or'

        '=='          'Equivalent'
        '/='          'Different'
        '>='          'EqualOrGreater'
        '<='          'EqualOrLess'
        '<'           'Less'
        '>'           'Greater'

        'program'     'Program'
        'with'        'With'
        'do'          'Do'
        'repeat'      'Repeat'
        'while'		  'While'
        'for'         'For'
        'from'        'From'
        'to'          'To'
        'by'          'By'
        'begin'       'Begin'
        'end'         'End'
        'func'        'Func'
        'read'        'Read'
        'write'       'Write'
        'writeln'     'Writeln'
        'if'          'If'
        'then'        'Then'
        'else'        'Else'
        'times'       'Times'
        'return'	  'ReturnToken'

        'home'		  'Home'
		'openeye'	  'OpenEye'
		'closeeye'	  'CloseEye' 		
		'forward'	  'Forward' 			
		'backward'	  'Backward' 		
		'rotatel'	  'Rotatel' 			
		'rotater'	  'Rotater'		
		'setposition' 'SetPosition'
		'arc'		  'Arc'		  

        'string'      'StringType'
        'number'      'NumberType'
        'boolean'     'BooleanType'

        'identifier'  'Tag'

end

#Here starts the grammar definition for the language
start Retina

rule
    
    Retina
    	: Code 															{result = Code.new(val[0])}


    Code       
        : 'program'
            InstructionList
          'end' ';'                                                   	{result = [MainBlock.new(InstructionList.new(val[1]))]}

        | FunctionDeclaration                                         
          Code                                                      	{code = [val[0]]; code += val[1]; 
          																 result = code}
        ;

    FunctionDeclaration
        : 'func' 'identifier' '('ArgumentList')'
          'begin'
            InstructionList
          'end' ';'                                                   	{instructions = InstructionList.new(val[6])
          																 identifier = Identifier.new(val[1],@func_table)
          																 result = FunctionDeclare.new(identifier,ArgumentList.new(val[3]),nil,instructions)}

        | 'func' 'identifier' '('ArgumentList')' '->' DataType
          'begin'
            InstructionList
          'end' ';'                                                   	{instructions = InstructionList.new(val[8])
          																 identifier = Identifier.new(val[1],@func_table)
          																 result = FunctionDeclare.new(identifier,ArgumentList.new(val[3]),val[6],instructions)}

        | 'func' 'identifier' '(' ')'
          'begin'
            InstructionList
          'end' ';'                                                   	{instructions = InstructionList.new(val[5])
          																 identifier = Identifier.new(val[1],@func_table)
          																 result = FunctionDeclare.new(identifier,nil,nil,instructions)}

        | 'func' 'identifier' '(' ')' '->' DataType
          'begin'
            InstructionList
          'end' ';'                                                   	{instructions = InstructionList.new(val[7])
          																 identifier = Identifier.new(val[1])
          																 result = FunctionDeclare.new(identifier,nil,val[5],instructions)}
        ;

    ArgumentList
        : ArgumentList ',' Argument                                   	{arguments = val[0]; arguments += [val[2]]; result = arguments}
        | Argument                                                    	{result = [val[0]]}
        ;

    Argument
        : DataType 'identifier'                                       	{identifier = Identifier.new(val[1])
        																 result = Argument.new(val[0], identifier)}
        ;

    DeclarationList
        : DeclarationList                                              
          Declaration ';'                                             	{declarations = val[0]; declarations += [val[1]] 
                                                                         result = declarations}

        | #Empty                                                      
          {result = []}
        ;

    InstructionList
        : InstructionList                                              
          Instruction ';'                                             	{instructions = val[0]; instructions += [val[1]] 
          																 result = instructions}
 
        | #Empty
          {result = []}
        ;

    Declaration
        : DataType 'identifier'                                       	{identifier = Identifier.new(val[1])
        																 result = Declaration.new(val[0],identifier,nil)}
        | DataType 'identifier' '=' Expression                        	{identifier = Identifier.new(val[1])
        																 result = Declaration.new(val[0],identifier,Expression.new(val[3]))}
        ;

    Instruction
        : FunctionCall                                                	{result = val[0]}
        | Assignment                                                  	{result = val[0]}

        | 'with'
            DeclarationList                                           
          'do'
            InstructionList
          'end'                                                   		{result = Block.new(DeclarationList.new(val[1]),InstructionList.new(val[3]))}

        | 'repeat' Expression 'times' 
            InstructionList 
          'end'                                                       	{result = RepeatCall.new(val[1],InstructionList.new(val[3]))}

        | 'for' 'identifier' 'from' Expression 'to' Expression 'do' 
            InstructionList 
          'end'                                                       	{result = ForCall.new(Identifier.new(val[1]),val[3],val[5],Number.new(Digit.new("1",nil,nil)),InstructionList.new(val[7]))}

        | 'for' 'identifier' 'from' Expression 'to' Expression 'by' Expression 'do' 
            InstructionList 
          'end'                                                       	{result = ForCall.new(Identifier.new(val[1]),val[3],val[5],val[7],InstructionList.new(val[9]))}

        | 'while' Expression 'do' 
            InstructionList 
          'end'                                                       	{result = WhileCall.new(Condition.new(val[1]),InstructionList.new(val[3]))}

        | 'if' Expression 'then' 
            InstructionList 
          'end'                                                       	{result = IfThen.new(Condition.new(val[1]),InstructionList.new(val[3]))}

        | 'if' Expression 'then' 
            InstructionList 
          'else' 
            InstructionList 
          'end'                                                       	{result = IfElse.new(Condition.new(val[1]),InstructionList.new(val[3]),InstructionList.new(val[5]))}
        
        | 'home' '(' ')'												{result = HomeCall.new()}
        | 'openeye' '(' ')'												{result = OpenEyeCall.new()}
        | 'closeeye'  '(' ')'											{result = CloseEyeCall.new()}
        | 'forward' '(' Expression ')'									{result = ForwardCall.new(Expression.new(val[2]))}
        | 'backward' '(' Expression ')'									{result = BackwardCall.new(Expression.new(val[2]))}
        | 'rotatel' '(' Expression ')'									{result = RotatelCall.new(Expression.new(val[2]))}
        | 'rotater' '(' Expression ')'									{result = RotaterCall.new(Expression.new(val[2]))}
        | 'setposition' '(' Expression ',' Expression ')'				{result = SetPositionCall.new(Expression.new(val[2]),Expression.new(val[4]))}
        | 'arc' '(' Expression ',' Expression ')' 						{result = ArcCall.new(Expression.new(val[2]),Expression.new(val[4]))}

        | 'read' 'identifier'                                         	{result = StdIn.new(Identifier.new(val[1]))}
        | 'write' Parameters                                          	{result = StdOut.new(Parameters.new(val[1]))}
        | 'writeln' Parameters                                        	{result = StdOutAndLine.new(Parameters.new(val[1]))}

        | 'return' Expression											{result = Return.new(Expression.new(val[1]))}
        ;

    FunctionCall
        : 'identifier' '(' Parameters ')'                             	{result = FunctionCall.new(Identifier.new(val[0]),Parameters.new(val[2]))}
        | 'identifier' '(' ')'                                        	{result = FunctionCall.new(Identifier.new(val[0]),nil)}
        ;

    Parameters
        : Parameters ',' Expression                                   	{param = val[0]; param += [Expression.new(val[2])]; result = param}
        | Expression                                                  	{result = [val[0]]}
        ;

    Assignment
        : 'identifier' '=' Expression                                 	{result = Assign.new(Identifier.new(val[0]),Expression.new(val[2]))}
        ;

    DataType
        : 'number'                                                    	{result = Type.new(val[0])}
        | 'boolean'                                                   	{result = Type.new(val[0])}
        ;

    Expression
        : 'charArray'                                                 	{result = CharString.new(val[0])}
        | 'identifier'                                                	{result = Identifier.new(val[0])}
        | FunctionCall                                                  {result = val[0]}

        | 'digit'                                                     	{result = Number.new(val[0])}
        | '-' Expression = UMINUS                           		  	{result = UnaryMinus.new(val[1])}
        | Expression '+' Expression                 					{result = Addition.new(val[0], val[2])}
        | Expression '-' Expression                 					{result = Substraction.new(val[0], val[2])}
        | Expression '*' Expression                 					{result = Multiplication.new(val[0], val[2])}
        | Expression '/' Expression                 					{result = ExactDivision.new(val[0], val[2])}
        | Expression '%' Expression                 					{result = ExactModulus.new(val[0], val[2])}
        | Expression 'div' Expression               					{result = WholeDivision.new(val[0], val[2])}
        | Expression 'mod' Expression               					{result = Modulus.new(val[0], val[2])}

        | 'true'                                                      	{result = Boolean.new(val[0])}
        | 'false'                                                     	{result = Boolean.new(val[0])}
        | Expression '<' Expression                 					{result = LessThan.new(val[0], val[2])}
        | Expression '>' Expression                 					{result = GreaterThan.new(val[0], val[2])}
        | Expression '<=' Expression                					{result = EqualLessThan.new(val[0], val[2])}
        | Expression '>=' Expression                					{result = EqualGreaterThan.new(val[0], val[2])}
        | Expression '==' Expression                					{result = Equivalence.new(val[0], val[2])}
        | Expression '/=' Expression                					{result = Difference.new(val[0], val[2])}
        | Expression 'and' Expression               					{result = Conjunction.new(val[0], val[2])}
        | Expression 'or' Expression                					{result = Disjunction.new(val[0], val[2])}
        | 'not' Expression                                   			{result = NegationOp.new(val[1])}
        | '(' Expression ')'                                          	{result = val[1]}
        ;

---- header

require_relative "retina_lexer"
require_relative "retina_ast"
require_relative "retina_symtable"

#Defining Syntax Error class. Will raise when input doesn't match
#grammar rules
class SyntacticError < RuntimeError
    def initialize(tok)
        @token = tok
    end

    def to_s
        "\n[Syntax ERROR] unexpected '#{@token}' token."   
    end
end

---- inner

def on_error(id, token, stack)
    raise SyntacticError::new(token)
end
   
#Captures every token in input through the lexer
def next_token
    token = @lexer.catch_lexeme
    return [false,false] unless token
    return [token.class,token]
end
   
#Finally it just matches the tokens to the grammar
def parse(lexer)
    @yydebug = true
    @lexer = lexer
    @tokens = []
    ast = do_parse
    return ast
end