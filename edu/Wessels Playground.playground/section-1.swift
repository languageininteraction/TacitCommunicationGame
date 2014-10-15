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
