// This is a generated file, do not edit!
// Generated by R.swift, see https://github.com/mac-cain13/R.swift

import Foundation
import Rswift
import UIKit

/// This `R` struct is code generated, and contains references to static resources.
struct R: Rswift.Validatable {
  static func validate() throws {
    try intern.validate()
  }
  
  /// This `R.color` struct is generated, and contains static references to 0 color palettes.
  struct color {
    private init() {}
  }
  
  /// This `R.file` struct is generated, and contains static references to 7 files.
  struct file {
    /// Resource file `Brandon Text W01 Medium.ttf`.
    static let brandonTextW01MediumTtf = FileResource(bundle: _R.hostingBundle, name: "Brandon Text W01 Medium", pathExtension: "ttf")
    /// Resource file `Brandon_bld.otf`.
    static let brandon_bldOtf = FileResource(bundle: _R.hostingBundle, name: "Brandon_bld", pathExtension: "otf")
    /// Resource file `Brandon_med.otf`.
    static let brandon_medOtf = FileResource(bundle: _R.hostingBundle, name: "Brandon_med", pathExtension: "otf")
    /// Resource file `Configurations.plist`.
    static let configurationsPlist = FileResource(bundle: _R.hostingBundle, name: "Configurations", pathExtension: "plist")
    /// Resource file `Gotham-Light.otf`.
    static let gothamLightOtf = FileResource(bundle: _R.hostingBundle, name: "Gotham-Light", pathExtension: "otf")
    /// Resource file `Settings.bundle`.
    static let settingsBundle = FileResource(bundle: _R.hostingBundle, name: "Settings", pathExtension: "bundle")
    /// Resource file `Webdings.ttf`.
    static let webdingsTtf = FileResource(bundle: _R.hostingBundle, name: "Webdings", pathExtension: "ttf")
    
    /// `bundle.URLForResource("Brandon Text W01 Medium", withExtension: "ttf")`
    static func brandonTextW01MediumTtf(_: Void) -> NSURL? {
      let fileResource = R.file.brandonTextW01MediumTtf
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    /// `bundle.URLForResource("Brandon_bld", withExtension: "otf")`
    static func brandon_bldOtf(_: Void) -> NSURL? {
      let fileResource = R.file.brandon_bldOtf
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    /// `bundle.URLForResource("Brandon_med", withExtension: "otf")`
    static func brandon_medOtf(_: Void) -> NSURL? {
      let fileResource = R.file.brandon_medOtf
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    /// `bundle.URLForResource("Configurations", withExtension: "plist")`
    static func configurationsPlist(_: Void) -> NSURL? {
      let fileResource = R.file.configurationsPlist
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    /// `bundle.URLForResource("Gotham-Light", withExtension: "otf")`
    static func gothamLightOtf(_: Void) -> NSURL? {
      let fileResource = R.file.gothamLightOtf
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    /// `bundle.URLForResource("Settings", withExtension: "bundle")`
    static func settingsBundle(_: Void) -> NSURL? {
      let fileResource = R.file.settingsBundle
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    /// `bundle.URLForResource("Webdings", withExtension: "ttf")`
    static func webdingsTtf(_: Void) -> NSURL? {
      let fileResource = R.file.webdingsTtf
      return fileResource.bundle.URLForResource(fileResource)
    }
    
    private init() {}
  }
  
  /// This `R.font` struct is generated, and contains static references to 5 fonts.
  struct font {
    /// Font `BrandonGrotesque-Bold`.
    static let brandonGrotesqueBold = FontResource(fontName: "BrandonGrotesque-Bold")
    /// Font `BrandonGrotesque-Medium`.
    static let brandonGrotesqueMedium = FontResource(fontName: "BrandonGrotesque-Medium")
    /// Font `BrandonTextW01-Medium`.
    static let brandonTextW01Medium = FontResource(fontName: "BrandonTextW01-Medium")
    /// Font `Gotham-Light`.
    static let gothamLight = FontResource(fontName: "Gotham-Light")
    /// Font `Webdings`.
    static let webdings = FontResource(fontName: "Webdings")
    
    /// `UIFont(name: "BrandonGrotesque-Bold", size: ...)`
    static func brandonGrotesqueBold(size size: CGFloat) -> UIFont? {
      return UIFont(resource: brandonGrotesqueBold, size: size)
    }
    
    /// `UIFont(name: "BrandonGrotesque-Medium", size: ...)`
    static func brandonGrotesqueMedium(size size: CGFloat) -> UIFont? {
      return UIFont(resource: brandonGrotesqueMedium, size: size)
    }
    
    /// `UIFont(name: "BrandonTextW01-Medium", size: ...)`
    static func brandonTextW01Medium(size size: CGFloat) -> UIFont? {
      return UIFont(resource: brandonTextW01Medium, size: size)
    }
    
    /// `UIFont(name: "Gotham-Light", size: ...)`
    static func gothamLight(size size: CGFloat) -> UIFont? {
      return UIFont(resource: gothamLight, size: size)
    }
    
    /// `UIFont(name: "Webdings", size: ...)`
    static func webdings(size size: CGFloat) -> UIFont? {
      return UIFont(resource: webdings, size: size)
    }
    
    private init() {}
  }
  
  /// This `R.image` struct is generated, and contains static references to 9 images.
  struct image {
    /// Image `action_bg_left`.
    static let action_bg_left = ImageResource(bundle: _R.hostingBundle, name: "action_bg_left")
    /// Image `action_bg_middle`.
    static let action_bg_middle = ImageResource(bundle: _R.hostingBundle, name: "action_bg_middle")
    /// Image `action_bg_right`.
    static let action_bg_right = ImageResource(bundle: _R.hostingBundle, name: "action_bg_right")
    /// Image `groups`.
    static let groups = ImageResource(bundle: _R.hostingBundle, name: "groups")
    /// Image `priority`.
    static let priority = ImageResource(bundle: _R.hostingBundle, name: "priority")
    /// Image `priority_bg_left`.
    static let priority_bg_left = ImageResource(bundle: _R.hostingBundle, name: "priority_bg_left")
    /// Image `priority_bg_middle`.
    static let priority_bg_middle = ImageResource(bundle: _R.hostingBundle, name: "priority_bg_middle")
    /// Image `priority_bg_right`.
    static let priority_bg_right = ImageResource(bundle: _R.hostingBundle, name: "priority_bg_right")
    /// Image `search`.
    static let search = ImageResource(bundle: _R.hostingBundle, name: "search")
    
    /// `UIImage(named: "action_bg_left", bundle: ..., traitCollection: ...)`
    static func action_bg_left(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.action_bg_left, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "action_bg_middle", bundle: ..., traitCollection: ...)`
    static func action_bg_middle(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.action_bg_middle, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "action_bg_right", bundle: ..., traitCollection: ...)`
    static func action_bg_right(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.action_bg_right, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "groups", bundle: ..., traitCollection: ...)`
    static func groups(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.groups, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "priority", bundle: ..., traitCollection: ...)`
    static func priority(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.priority, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "priority_bg_left", bundle: ..., traitCollection: ...)`
    static func priority_bg_left(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.priority_bg_left, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "priority_bg_middle", bundle: ..., traitCollection: ...)`
    static func priority_bg_middle(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.priority_bg_middle, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "priority_bg_right", bundle: ..., traitCollection: ...)`
    static func priority_bg_right(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.priority_bg_right, compatibleWithTraitCollection: traitCollection)
    }
    
    /// `UIImage(named: "search", bundle: ..., traitCollection: ...)`
    static func search(compatibleWithTraitCollection traitCollection: UITraitCollection? = nil) -> UIImage? {
      return UIImage(resource: R.image.search, compatibleWithTraitCollection: traitCollection)
    }
    
    private init() {}
  }
  
  private struct intern: Rswift.Validatable {
    static func validate() throws {
      try _R.validate()
    }
    
    private init() {}
  }
  
  /// This `R.nib` struct is generated, and contains static references to 9 nibs.
  struct nib {
    /// Nib `AutoCompletionTableCell`.
    static let autoCompletionTableCell = _R.nib._AutoCompletionTableCell()
    /// Nib `CommentTableViewCell`.
    static let commentTableViewCell = _R.nib._CommentTableViewCell()
    /// Nib `ConversationTableViewCell`.
    static let conversationTableViewCell = _R.nib._ConversationTableViewCell()
    /// Nib `DeliverableTableViewCell`.
    static let deliverableTableViewCell = _R.nib._DeliverableTableViewCell()
    /// Nib `OrganizationTableViewCell`.
    static let organizationTableViewCell = _R.nib._OrganizationTableViewCell()
    /// Nib `StartOfConversationView`.
    static let startOfConversationView = _R.nib._StartOfConversationView()
    /// Nib `StreamTableViewCell`.
    static let streamTableViewCell = _R.nib._StreamTableViewCell()
    /// Nib `TimelineAgendaItemTableViewCell`.
    static let timelineAgendaItemTableViewCell = _R.nib._TimelineAgendaItemTableViewCell()
    /// Nib `TimelineDeliverableTableViewCell`.
    static let timelineDeliverableTableViewCell = _R.nib._TimelineDeliverableTableViewCell()
    
    /// `UINib(name: "AutoCompletionTableCell", bundle: ...)`
    static func autoCompletionTableCell(_: Void) -> UINib {
      return UINib(resource: R.nib.autoCompletionTableCell)
    }
    
    /// `UINib(name: "CommentTableViewCell", bundle: ...)`
    static func commentTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.commentTableViewCell)
    }
    
    /// `UINib(name: "ConversationTableViewCell", bundle: ...)`
    static func conversationTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.conversationTableViewCell)
    }
    
    /// `UINib(name: "DeliverableTableViewCell", bundle: ...)`
    static func deliverableTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.deliverableTableViewCell)
    }
    
    /// `UINib(name: "OrganizationTableViewCell", bundle: ...)`
    static func organizationTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.organizationTableViewCell)
    }
    
    /// `UINib(name: "StartOfConversationView", bundle: ...)`
    static func startOfConversationView(_: Void) -> UINib {
      return UINib(resource: R.nib.startOfConversationView)
    }
    
    /// `UINib(name: "StreamTableViewCell", bundle: ...)`
    static func streamTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.streamTableViewCell)
    }
    
    /// `UINib(name: "TimelineAgendaItemTableViewCell", bundle: ...)`
    static func timelineAgendaItemTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.timelineAgendaItemTableViewCell)
    }
    
    /// `UINib(name: "TimelineDeliverableTableViewCell", bundle: ...)`
    static func timelineDeliverableTableViewCell(_: Void) -> UINib {
      return UINib(resource: R.nib.timelineDeliverableTableViewCell)
    }
    
    private init() {}
  }
  
  /// This `R.reuseIdentifier` struct is generated, and contains static references to 7 reuse identifiers.
  struct reuseIdentifier {
    /// Reuse identifier `AgendaItemTableViewCell`.
    static let agendaItemTableViewCell: ReuseIdentifier<AgendaItemTableViewCell> = ReuseIdentifier(identifier: "AgendaItemTableViewCell")
    /// Reuse identifier `ConversationTableViewCell`.
    static let conversationTableViewCell: ReuseIdentifier<ConversationTableViewCell> = ReuseIdentifier(identifier: "ConversationTableViewCell")
    /// Reuse identifier `DeliverableTableViewCell`.
    static let deliverableTableViewCell: ReuseIdentifier<DeliverableTableViewCell> = ReuseIdentifier(identifier: "DeliverableTableViewCell")
    /// Reuse identifier `OrganizationTableViewCell`.
    static let organizationTableViewCell: ReuseIdentifier<OrganizationTableViewCell> = ReuseIdentifier(identifier: "OrganizationTableViewCell")
    /// Reuse identifier `StreamTableViewCell`.
    static let streamTableViewCell: ReuseIdentifier<StreamTableViewCell> = ReuseIdentifier(identifier: "StreamTableViewCell")
    /// Reuse identifier `TimelineAgendaItemTableViewCell`.
    static let timelineAgendaItemTableViewCell: ReuseIdentifier<TimelineAgendaItemTableViewCell> = ReuseIdentifier(identifier: "TimelineAgendaItemTableViewCell")
    /// Reuse identifier `TimelineDeliverableTableViewCell`.
    static let timelineDeliverableTableViewCell: ReuseIdentifier<TimelineDeliverableTableViewCell> = ReuseIdentifier(identifier: "TimelineDeliverableTableViewCell")
    
    private init() {}
  }
  
  /// This `R.segue` struct is generated, and contains static references to 5 view controllers.
  struct segue {
    /// This struct is generated for `AgendaItemViewController`, and contains static references to 1 segues.
    struct agendaItemViewController {
      /// Segue identifier `embed`.
      static let embed: StoryboardSegueIdentifier<UIStoryboardSegue, AgendaItemViewController, TimelineTableViewController> = StoryboardSegueIdentifier(identifier: "embed")
      
      /// Optionally returns a typed version of segue `embed`.
      /// Returns nil if either the segue identifier, the source, destination, or segue types don't match.
      /// For use inside `prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)`.
      static func embed(segue segue: UIStoryboardSegue) -> TypedStoryboardSegueInfo<UIStoryboardSegue, AgendaItemViewController, TimelineTableViewController>? {
        return TypedStoryboardSegueInfo(segueIdentifier: R.segue.agendaItemViewController.embed, segue: segue)
      }
      
      private init() {}
    }
    
    /// This struct is generated for `ConversationViewController`, and contains static references to 1 segues.
    struct conversationViewController {
      /// Segue identifier `embed`.
      static let embed: StoryboardSegueIdentifier<UIStoryboardSegue, ConversationViewController, MainPageViewController> = StoryboardSegueIdentifier(identifier: "embed")
      
      /// Optionally returns a typed version of segue `embed`.
      /// Returns nil if either the segue identifier, the source, destination, or segue types don't match.
      /// For use inside `prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)`.
      static func embed(segue segue: UIStoryboardSegue) -> TypedStoryboardSegueInfo<UIStoryboardSegue, ConversationViewController, MainPageViewController>? {
        return TypedStoryboardSegueInfo(segueIdentifier: R.segue.conversationViewController.embed, segue: segue)
      }
      
      private init() {}
    }
    
    /// This struct is generated for `ConversationsTableViewController`, and contains static references to 1 segues.
    struct conversationsTableViewController {
      /// Segue identifier `showConversation`.
      static let showConversation: StoryboardSegueIdentifier<UIStoryboardSegue, ConversationsTableViewController, ConversationViewController> = StoryboardSegueIdentifier(identifier: "showConversation")
      
      /// Optionally returns a typed version of segue `showConversation`.
      /// Returns nil if either the segue identifier, the source, destination, or segue types don't match.
      /// For use inside `prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)`.
      static func showConversation(segue segue: UIStoryboardSegue) -> TypedStoryboardSegueInfo<UIStoryboardSegue, ConversationsTableViewController, ConversationViewController>? {
        return TypedStoryboardSegueInfo(segueIdentifier: R.segue.conversationsTableViewController.showConversation, segue: segue)
      }
      
      private init() {}
    }
    
    /// This struct is generated for `DeliverableViewController`, and contains static references to 1 segues.
    struct deliverableViewController {
      /// Segue identifier `embed`.
      static let embed: StoryboardSegueIdentifier<UIStoryboardSegue, DeliverableViewController, TimelineTableViewController> = StoryboardSegueIdentifier(identifier: "embed")
      
      /// Optionally returns a typed version of segue `embed`.
      /// Returns nil if either the segue identifier, the source, destination, or segue types don't match.
      /// For use inside `prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)`.
      static func embed(segue segue: UIStoryboardSegue) -> TypedStoryboardSegueInfo<UIStoryboardSegue, DeliverableViewController, TimelineTableViewController>? {
        return TypedStoryboardSegueInfo(segueIdentifier: R.segue.deliverableViewController.embed, segue: segue)
      }
      
      private init() {}
    }
    
    /// This struct is generated for `OrganizationViewController`, and contains static references to 1 segues.
    struct organizationViewController {
      /// Segue identifier `embed`.
      static let embed: StoryboardSegueIdentifier<UIStoryboardSegue, OrganizationViewController, MainPageViewController> = StoryboardSegueIdentifier(identifier: "embed")
      
      /// Optionally returns a typed version of segue `embed`.
      /// Returns nil if either the segue identifier, the source, destination, or segue types don't match.
      /// For use inside `prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)`.
      static func embed(segue segue: UIStoryboardSegue) -> TypedStoryboardSegueInfo<UIStoryboardSegue, OrganizationViewController, MainPageViewController>? {
        return TypedStoryboardSegueInfo(segueIdentifier: R.segue.organizationViewController.embed, segue: segue)
      }
      
      private init() {}
    }
    
    private init() {}
  }
  
  /// This `R.storyboard` struct is generated, and contains static references to 7 storyboards.
  struct storyboard {
    /// Storyboard `AgendaItem`.
    static let agendaItem = _R.storyboard.agendaItem()
    /// Storyboard `Conversations`.
    static let conversations = _R.storyboard.conversations()
    /// Storyboard `Deliverable`.
    static let deliverable = _R.storyboard.deliverable()
    /// Storyboard `LaunchScreen`.
    static let launchScreen = _R.storyboard.launchScreen()
    /// Storyboard `Login`.
    static let login = _R.storyboard.login()
    /// Storyboard `Main`.
    static let main = _R.storyboard.main()
    /// Storyboard `Organizations`.
    static let organizations = _R.storyboard.organizations()
    
    /// `UIStoryboard(name: "AgendaItem", bundle: ...)`
    static func agendaItem(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.agendaItem)
    }
    
    /// `UIStoryboard(name: "Conversations", bundle: ...)`
    static func conversations(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.conversations)
    }
    
    /// `UIStoryboard(name: "Deliverable", bundle: ...)`
    static func deliverable(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.deliverable)
    }
    
    /// `UIStoryboard(name: "LaunchScreen", bundle: ...)`
    static func launchScreen(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.launchScreen)
    }
    
    /// `UIStoryboard(name: "Login", bundle: ...)`
    static func login(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.login)
    }
    
    /// `UIStoryboard(name: "Main", bundle: ...)`
    static func main(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.main)
    }
    
    /// `UIStoryboard(name: "Organizations", bundle: ...)`
    static func organizations(_: Void) -> UIStoryboard {
      return UIStoryboard(resource: R.storyboard.organizations)
    }
    
    private init() {}
  }
  
  /// This `R.string` struct is generated, and contains static references to 0 localization tables.
  struct string {
    private init() {}
  }
  
  private init() {}
}

struct _R: Rswift.Validatable {
  static let applicationLocale = hostingBundle.preferredLocalizations.first.flatMap(NSLocale.init) ?? NSLocale.currentLocale()
  static let hostingBundle = NSBundle(identifier: "com.sizung.app.ios") ?? NSBundle.mainBundle()
  
  static func validate() throws {
    try storyboard.validate()
  }
  
  struct nib {
    struct _AutoCompletionTableCell: NibResourceType {
      let bundle = _R.hostingBundle
      let name = "AutoCompletionTableCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> AutoCompletionTableCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? AutoCompletionTableCell
      }
      
      private init() {}
    }
    
    struct _CommentTableViewCell: NibResourceType {
      let bundle = _R.hostingBundle
      let name = "CommentTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> CommentTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? CommentTableViewCell
      }
      
      private init() {}
    }
    
    struct _ConversationTableViewCell: NibResourceType, ReuseIdentifierType {
      typealias ReusableType = ConversationTableViewCell
      
      let bundle = _R.hostingBundle
      let identifier = "ConversationTableViewCell"
      let name = "ConversationTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> ConversationTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? ConversationTableViewCell
      }
      
      private init() {}
    }
    
    struct _DeliverableTableViewCell: NibResourceType, ReuseIdentifierType {
      typealias ReusableType = DeliverableTableViewCell
      
      let bundle = _R.hostingBundle
      let identifier = "DeliverableTableViewCell"
      let name = "DeliverableTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> DeliverableTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? DeliverableTableViewCell
      }
      
      private init() {}
    }
    
    struct _OrganizationTableViewCell: NibResourceType, ReuseIdentifierType {
      typealias ReusableType = OrganizationTableViewCell
      
      let bundle = _R.hostingBundle
      let identifier = "OrganizationTableViewCell"
      let name = "OrganizationTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> OrganizationTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? OrganizationTableViewCell
      }
      
      private init() {}
    }
    
    struct _StartOfConversationView: NibResourceType {
      let bundle = _R.hostingBundle
      let name = "StartOfConversationView"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> UIView? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? UIView
      }
      
      private init() {}
    }
    
    struct _StreamTableViewCell: NibResourceType, ReuseIdentifierType {
      typealias ReusableType = StreamTableViewCell
      
      let bundle = _R.hostingBundle
      let identifier = "StreamTableViewCell"
      let name = "StreamTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> StreamTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? StreamTableViewCell
      }
      
      private init() {}
    }
    
    struct _TimelineAgendaItemTableViewCell: NibResourceType, ReuseIdentifierType {
      typealias ReusableType = TimelineAgendaItemTableViewCell
      
      let bundle = _R.hostingBundle
      let identifier = "TimelineAgendaItemTableViewCell"
      let name = "TimelineAgendaItemTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> TimelineAgendaItemTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? TimelineAgendaItemTableViewCell
      }
      
      private init() {}
    }
    
    struct _TimelineDeliverableTableViewCell: NibResourceType, ReuseIdentifierType {
      typealias ReusableType = TimelineDeliverableTableViewCell
      
      let bundle = _R.hostingBundle
      let identifier = "TimelineDeliverableTableViewCell"
      let name = "TimelineDeliverableTableViewCell"
      
      func firstView(owner ownerOrNil: AnyObject?, options optionsOrNil: [NSObject : AnyObject]? = nil) -> TimelineDeliverableTableViewCell? {
        return instantiateWithOwner(ownerOrNil, options: optionsOrNil)[0] as? TimelineDeliverableTableViewCell
      }
      
      private init() {}
    }
    
    private init() {}
  }
  
  struct storyboard: Rswift.Validatable {
    static func validate() throws {
      try conversations.validate()
      try main.validate()
    }
    
    struct agendaItem: StoryboardResourceWithInitialControllerType {
      typealias InitialController = AgendaItemViewController
      
      let bundle = _R.hostingBundle
      let name = "AgendaItem"
      
      private init() {}
    }
    
    struct conversations: StoryboardResourceWithInitialControllerType, Rswift.Validatable {
      typealias InitialController = UIViewController
      
      let agendaItemsTableViewController = StoryboardViewControllerResource<AgendaItemsTableViewController>(identifier: "AgendaItemsTableViewController")
      let bundle = _R.hostingBundle
      let conversationDeliverablesTableViewController = StoryboardViewControllerResource<ConversationDeliverablesTableViewController>(identifier: "ConversationDeliverablesTableViewController")
      let conversationsTableViewController = StoryboardViewControllerResource<ConversationsTableViewController>(identifier: "ConversationsTableViewController")
      let name = "Conversations"
      let timelineTableViewController = StoryboardViewControllerResource<TimelineTableViewController>(identifier: "TimelineTableViewController")
      
      func agendaItemsTableViewController(_: Void) -> AgendaItemsTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(agendaItemsTableViewController)
      }
      
      func conversationDeliverablesTableViewController(_: Void) -> ConversationDeliverablesTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(conversationDeliverablesTableViewController)
      }
      
      func conversationsTableViewController(_: Void) -> ConversationsTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(conversationsTableViewController)
      }
      
      func timelineTableViewController(_: Void) -> TimelineTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(timelineTableViewController)
      }
      
      static func validate() throws {
        if UIImage(named: "IconAgendaItem") == nil { throw ValidationError(description: "[R.swift] Image named 'IconAgendaItem' is used in storyboard 'Conversations', but couldn't be loaded.") }
        if _R.storyboard.conversations().conversationsTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'conversationsTableViewController' could not be loaded from storyboard 'Conversations' as 'ConversationsTableViewController'.") }
        if _R.storyboard.conversations().timelineTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'timelineTableViewController' could not be loaded from storyboard 'Conversations' as 'TimelineTableViewController'.") }
        if _R.storyboard.conversations().conversationDeliverablesTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'conversationDeliverablesTableViewController' could not be loaded from storyboard 'Conversations' as 'ConversationDeliverablesTableViewController'.") }
        if _R.storyboard.conversations().agendaItemsTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'agendaItemsTableViewController' could not be loaded from storyboard 'Conversations' as 'AgendaItemsTableViewController'.") }
      }
      
      private init() {}
    }
    
    struct deliverable: StoryboardResourceWithInitialControllerType {
      typealias InitialController = DeliverableViewController
      
      let bundle = _R.hostingBundle
      let name = "Deliverable"
      
      private init() {}
    }
    
    struct launchScreen: StoryboardResourceWithInitialControllerType {
      typealias InitialController = UIViewController
      
      let bundle = _R.hostingBundle
      let name = "LaunchScreen"
      
      private init() {}
    }
    
    struct login: StoryboardResourceWithInitialControllerType {
      typealias InitialController = LoginViewController
      
      let bundle = _R.hostingBundle
      let name = "Login"
      
      private init() {}
    }
    
    struct main: StoryboardResourceWithInitialControllerType, Rswift.Validatable {
      typealias InitialController = OrganizationViewController
      
      let accountViewController = StoryboardViewControllerResource<AccountViewController>(identifier: "AccountViewController")
      let agendaItemsTableViewController = StoryboardViewControllerResource<AgendaItemsTableViewController>(identifier: "AgendaItemsTableViewController")
      let bundle = _R.hostingBundle
      let mainViewController = StoryboardViewControllerResource<OrganizationViewController>(identifier: "MainViewController")
      let name = "Main"
      let streamTableViewController = StoryboardViewControllerResource<StreamTableViewController>(identifier: "StreamTableViewController")
      let userDeliverablesTableViewController = StoryboardViewControllerResource<UserDeliverablesTableViewController>(identifier: "UserDeliverablesTableViewController")
      
      func accountViewController(_: Void) -> AccountViewController? {
        return UIStoryboard(resource: self).instantiateViewController(accountViewController)
      }
      
      func agendaItemsTableViewController(_: Void) -> AgendaItemsTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(agendaItemsTableViewController)
      }
      
      func mainViewController(_: Void) -> OrganizationViewController? {
        return UIStoryboard(resource: self).instantiateViewController(mainViewController)
      }
      
      func streamTableViewController(_: Void) -> StreamTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(streamTableViewController)
      }
      
      func userDeliverablesTableViewController(_: Void) -> UserDeliverablesTableViewController? {
        return UIStoryboard(resource: self).instantiateViewController(userDeliverablesTableViewController)
      }
      
      static func validate() throws {
        if UIImage(named: "groups") == nil { throw ValidationError(description: "[R.swift] Image named 'groups' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIImage(named: "priority") == nil { throw ValidationError(description: "[R.swift] Image named 'priority' is used in storyboard 'Main', but couldn't be loaded.") }
        if UIImage(named: "search") == nil { throw ValidationError(description: "[R.swift] Image named 'search' is used in storyboard 'Main', but couldn't be loaded.") }
        if _R.storyboard.main().agendaItemsTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'agendaItemsTableViewController' could not be loaded from storyboard 'Main' as 'AgendaItemsTableViewController'.") }
        if _R.storyboard.main().accountViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'accountViewController' could not be loaded from storyboard 'Main' as 'AccountViewController'.") }
        if _R.storyboard.main().mainViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'mainViewController' could not be loaded from storyboard 'Main' as 'OrganizationViewController'.") }
        if _R.storyboard.main().userDeliverablesTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'userDeliverablesTableViewController' could not be loaded from storyboard 'Main' as 'UserDeliverablesTableViewController'.") }
        if _R.storyboard.main().streamTableViewController() == nil { throw ValidationError(description:"[R.swift] ViewController with identifier 'streamTableViewController' could not be loaded from storyboard 'Main' as 'StreamTableViewController'.") }
      }
      
      private init() {}
    }
    
    struct organizations: StoryboardResourceWithInitialControllerType {
      typealias InitialController = OrganizationsViewController
      
      let bundle = _R.hostingBundle
      let name = "Organizations"
      
      private init() {}
    }
    
    private init() {}
  }
  
  private init() {}
}