import UIKit

var a:Dictionary = [:]

a["een"] = 1
/*a["twee"] = 2*/
println(a)

for i in [1,2,3]
{
    println(i)
    break
}

var b = true

if(b)
{
    a
}

var opt: String? = "wessel"
opt
opt == nil

if let name = opt
{
    a
    println("Hoi \(name)")
}

var v = 3

switch v
{
    case 1: 1
    case let x where x*10 > 10 : 0
    case 2,3: 2
    default: 3
}

let interestingNumbers = [
    "Prime": [2, 3, 5, 7, 11, 13],
    "Fibonacci": [1, 1, 2, 3, 5, 8],
    "Square": [1, 4, 9, 16, 25],
]
var largest = 0
var largest_kind = ""

for (kind, numbers) in interestingNumbers {
    for number in numbers {
        if number > largest {
            largest = number
            largest_kind = kind
        }
    }
}

largest
largest_kind

func square	(n: Int) -> String
{
    return "The answer is "+String(n * n)
}

square(3);

func average(nrs: Float...) -> Float
{
    var total:Float = 0;
    var length:Float = 0;
    
    for n in nrs
    {
        total += n;
        length += 1;
    }
    return Float(total/length)
}

average(2,2,3)

let numbers = [1,2,3,4,5,10,9,8,7,6]
numbers


class NamedShape {
    var numberOfSides: Int = 0
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    func simpleDescription() -> String {
        return "A shape with \(numberOfSides) sides."
    }
}

class Circle:NamedShape
{

    var radius: Int;
    
    init(name:String,radius:Int)
    {
        self.radius = radius;
        super.init(name: name);
    }

    override func simpleDescription() -> String
    {
        return "A circle with a radius of \(self.radius)"
    }
    
}

var c = Circle(name: "wessel",radius: 5)
c.simpleDescription()

func sort(input:Int...) -> [Int]
{
    var output = [Int]()
    
    var c = 0
    
    for nr in input
    {
        if c == 0
        {
            output.append(nr)
        }
        else
        {
            var n = 0
            for sorted_number in output
            {
                if nr > sorted_number
                {
                    
                    output.insert(nr,atIndex:n)
                    break
                }
                else
                {
                    n += 1;
                }
            }
        }
        
        c += 1;
    }

    return output
    
}

sort(1,5,6,2,3,10,15,3,8,100,0,23)

class Tree
{
    var realsize:Int = 0
    
    var size:Int
    {
        get
        {
            return realsize*2
        }
        set(value)
            {
                realsize = value + 1
        }
    }

    init(size:Int)
    {
        self.realsize = size
    }
}

var t = Tree(size:10)

t.size = 80
println(t.size)

enum Rank: Int {
    case Ace = 1
    case Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten
    case Jack, Queen, King
    func simpleDescription() -> String {
        switch self {
        case .Ace:
            return "ace"
        case .Jack:
            return "jack"
        case .Queen:
            return "queen"
        case .King:
            return "king"
        default:
            return String(self.toRaw())
        }
    }
}

func highest_rank(rank1:Rank,rank2:Rank) -> String
{
    if rank1.toRaw() > rank2.toRaw()
    {
        return rank1.simpleDescription()
    }
    else
    {
        return rank2.simpleDescription()
    }
}

var r1 = Rank.Six
var r2 = Rank.Three

highest_rank(r1,r2)

enum Suit {
    case Spades, Hearts, Diamonds, Clubs
    func simpleDescription() -> String {
        switch self {
        case .Spades:
            return "spades"
        case .Hearts:
            return "hearts"
        case .Diamonds:
            return "diamonds"
        case .Clubs:
            return "clubs"
        }
    }

    func color() -> String
    {
        if self == Spades || self == Hearts
        {
            return "black"
        }
        else
        {
            return "red"
        }
    }

   
}
    
let hearts = Suit.Diamonds
let heartsDescription = hearts.simpleDescription()
hearts.color()

enum OS
{
    case Windows(String)
    case Mac(String)
    case Linux(String)
}

var keuze = OS.Linux("Handigste")

switch keuze
{
    case let .Linux(reden): println(reden)
    default: println("Oja");
}

func reverse_str(s:String) -> String
{
    var result = ""
    
    for letter in s
    {
        result = String(letter)+result;
    }
    
    return result
}

reverse_str("wessel")
