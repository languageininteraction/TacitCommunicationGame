import UIKit

protocol PassControlToSubControllerProtocol
{
    func subControllerFinished(subController:AnyObject)//TakeControlFromSuperControllerProtocol)
}

protocol TakeControlFromSuperControllerProtocol
{
    func setSuperController(superController:PassControlToSubControllerProtocol)
}

class ViewSubController: UIViewController, TakeControlFromSuperControllerProtocol
{
    var superController: PassControlToSubControllerProtocol?
	
	func setSuperController(superController:PassControlToSubControllerProtocol) {
		self.superController = superController
	}
}

class TableViewSubController: UITableViewController, TakeControlFromSuperControllerProtocol
{
    var superController: PassControlToSubControllerProtocol?
	
	func setSuperController(superController:PassControlToSubControllerProtocol) {
		self.superController = superController
	}
}

