module Main
where

import Char

data Expression = Num Int
                | Add Expression Expression
                | Sub Expression Expression
                | Mul Expression Expression
                | Div Expression Expression
                | Var Char
                deriving (Show)
                
data Assign = Assign Char Expression
              deriving (Show)

type Parser a = String -> Maybe (a, String)

parse = assign

assign :: String -> Assign
assign s = Assign id expr
    where (id, expr) = case assign' s of 
            Nothing -> error "Invalid assignment"
            Just ((a, b), _) -> (a, (Num (read [b])))
                   
assign' = letter <+-> literal '=' <+> digit

-- Basic parsers (Building Blocks)
ident :: Parser String
ident = token (letter <+> iter alphanum >>> cons)

char :: Parser Char
char [] = Nothing
char (c:cs) = Just (c, cs)

digit :: Parser Char
digit = char <=> isDigit

space :: Parser Char
space = char <=> isSpace    

letter :: Parser Char
letter = char <=> isAlpha

letters :: Parser String
letters = iter letter

alphanum :: Parser Char
alphanum = digit <|> letter

literal :: Char -> Parser Char
literal c = char <=> (==c)

return :: a -> Parser a
return a cs = Just(a,cs)

fail :: Parser a
fail _ = Nothing

token :: Parser a -> Parser a
token = (<+->  iter space)

cons :: (a, [a]) -> [a]
cons (hd, tl) = hd:tl

-- Parser combinators (Operations)   
iterate :: Parser a -> Int -> Parser [a]
iterate m 0 = Main.return []
iterate m x = m <+> Main.iterate m (x-1) >>> cons

iter :: Parser a -> Parser [a]
iter m = m <+> iter m >>> cons 
        <|> Main.return []

-- Combine two parsers using a 'or' type operation        
infixl 3 <|>
(<|>) :: Parser a -> Parser a -> Parser a 
(m <|> n) cs = case m cs of 
    Nothing -> n cs 
    mcs -> mcs
    
infixl 5 >>>
(>>>) :: Parser a -> (a -> b) -> Parser b
(m >>> n) cs = case m cs of
    Nothing -> Nothing
    Just (a, cs') -> Just (n a, cs')

-- Sequence operator that pairs up two parsers
infixl 6 <+>
(<+>) :: Parser a -> Parser b -> Parser (a, b)
(m <+> n) cs = case m cs of
    Nothing -> Nothing
    Just (a, cs') -> case n cs' of
        Nothing -> Nothing
        Just (b, cs2) -> Just((a, b), cs2) 
        
infixl 6 <-+> 
(<-+> ) :: Parser a -> Parser b -> Parser b
(m <-+>  n) cs = case m cs of
    Nothing -> Nothing
    Just (a, cs') -> case n cs' of
        Nothing -> Nothing
        Just (b, cs2) -> Just(b, cs2) 
        
infixl 6 <+-> 
(<+-> ) :: Parser a -> Parser b -> Parser a
(m <+->  n) cs = case m cs of
    Nothing -> Nothing
    Just (a, cs') -> case n cs' of
        Nothing -> Nothing
        Just (b, cs2) -> Just(a, cs2) 

-- Given a parser and a predicate, return the result of the parser only if
-- it also satisfies the predicate.    
infix 7 <=> 
(<=>) :: Parser a -> (a -> Bool) -> Parser a 
(m <=> p) cs =
        Nothing     -> Nothing 
        Just(a,cs)  -> if p a then Just(a,cs) else Nothing


