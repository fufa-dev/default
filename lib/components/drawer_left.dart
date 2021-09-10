import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/components/expansion_tile_drawer_fav.dart';
import 'package:flutter_app/components/expansion_tile_drawer_nodes.dart';
import 'package:flutter_app/components/search_delegate.dart';
import 'package:flutter_app/generated/i18n.dart';
import 'package:flutter_app/models/jinrishici.dart';
import 'package:flutter_app/models/web/item_fav_node.dart';
import 'package:flutter_app/models/web/node.dart';
import 'package:flutter_app/network/api_network.dart';
import 'package:flutter_app/network/dio_web.dart';
import 'package:flutter_app/pages/page_following.dart';
import 'package:flutter_app/pages/page_history_hot_category.dart';
import 'package:flutter_app/pages/page_login.dart';
// import 'package:flutter_app/pages/page_new_topic.dart';
import 'package:flutter_app/pages/page_node_topics.dart';
import 'package:flutter_app/pages/page_notifications.dart';
import 'package:flutter_app/pages/page_profile.dart';
import 'package:flutter_app/pages/page_recent_read_topics.dart';
import 'package:flutter_app/pages/page_setting.dart';
import 'package:flutter_app/states/model_display.dart';
import 'package:flutter_app/utils/google_now_images.dart';
import 'package:flutter_app/utils/sp_helper.dart';
import 'package:flutter_app/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DrawerLeft extends StatefulWidget {
  @override
  _DrawerLeftState createState() => _DrawerLeftState();
}

class _DrawerLeftState extends State<DrawerLeft> {
  String userName = "", avatar = "", notificationCount = "";
  Poem poemOne;
  List<FavNode> listFavNode; //收藏的节点
  List<NodeItem> listHotNode; //最热节点

  @override
  void initState() {
    super.initState();
    checkLoginState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle aboutTextStyle = themeData.textTheme.bodyText1;
    final TextStyle linkStyle =
        themeData.textTheme.bodyText1.copyWith(color: themeData.accentColor);

    return SizedBox(
      child: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    InkWell(
                      child: userName.isEmpty
                          ? Container(
                              child: Text(
                                S.of(context).login,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              width: 72,
                              alignment: Alignment.bottomCenter,
                            )
                          : Opacity(
                              opacity: 0.9,
                              child: Container(
                                child: Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                      onTap: () {
                        if (userName.isEmpty) {
                          var future = Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                  fullscreenDialog: true));
                          future.then((value) {
                            // 直接close登录页则value为null；登录成功 value 为 true
                            if (value != null && value) {
                              setState(() {
                                checkLoginState();
                              });
                              //尝试领取每日奖励
                              checkDailyAward();
                            }
                          });
                        } else {
                          // _launchURL(Strings.v2exHost + '/member/' + userName);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(userName, avatar),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                accountEmail: GestureDetector(
                  onTap: () {
                    if (poemOne != null) {
                      HapticFeedback.mediumImpact(); // 震动反馈
                      // 显示诗词dialog
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => SimpleDialog(
                                children: <Widget>[
                                  Center(
                                    child: Column(
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4, right: 4),
                                          child: Text(
                                            poemOne.data.origin.title,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 20.0,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        SizedBox(height: 10.0),
                                        Text(
                                          '[' +
                                              poemOne.data.origin.dynasty +
                                              "] " +
                                              poemOne.data.origin.author,
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).accentColor,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            children:
                                                poemOne.data.origin.content
                                                    .map((value) => Text(
                                                          value
                                                              .replaceAll(
                                                                  '。', '。\n')
                                                              .replaceAll(
                                                                  '，', '，\n')
                                                              .replaceAll(
                                                                  '？', '？\n')
                                                              .replaceAll(
                                                                  '！', '！\n'),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 16.0),
                                                        ))
                                                    .toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ));
                    }
                  },
                  child: Opacity(
                    child: Container(
                      child: Text(
                        poemOne != null ? poemOne.data.content : "",
                        style: TextStyle(fontSize: 14),
                      ),
                      // color: Colors.grey,
                      padding: EdgeInsets.all(userName.isEmpty ? 0 : 2),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    opacity: 0.9,
                  ),
                ),
                // 随机一句短诗词 poems[Random().nextInt(poems.length - 1)]
                currentAccountPicture: GestureDetector(
                  onTap: () {
                    if (userName.isEmpty) {
                      //未登录
                      var future = Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginPage(),
                              fullscreenDialog: true));
                      future.then((value) {
                        // 直接close登录页则value为null；登录成功 value 为 true
                        if (value != null && value) {
                          setState(() {
                            checkLoginState();
                          });
                          //尝试领取每日奖励
                          checkDailyAward();
                        }
                      });
                    } else {
                      // _launchURL(Strings.v2exHost + '/member/' + userName);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ProfilePage(userName, avatar)),
                      );
                    }
                  },
                  child: Hero(
                    tag: 'avatar',
                    transitionOnUserGestures: true,
                    child: Material(
                      shape: CircleBorder(
                          side: BorderSide(color: Colors.white, width: 2)),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: avatar.isNotEmpty
                            ? CachedNetworkImageProvider(avatar)
                            : AssetImage("assets/images/ic_person.png"),
                      ),
                    ),
                  ),
                ),
                // 这里可以根据一天的不同时间显示不同的background，增加美观
                decoration: BoxDecoration(
                  color: Provider.of<DisplayModel>(context).materialColor,
                  image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(GoogleNowImg.allLocation[
                              GoogleNowImg.getRandomLocationIndex()]
                          [GoogleNowImg.getCurrentTimeIndex()])),
                ),
                margin: null,
              ),
              ListTile(
                leading: Icon(Icons.whatshot),
                title: Text(S.of(context).history),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HistoryHotCategory()));
                },
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text(S.of(context).recentRead),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RecentReadTopicsPage()));
                },
              ),
              ExpansionTileDrawerNodes(
                leading: Icon(Icons.apps),
                title: Text(S.of(context).nodes),
                onExpansionChanged: (bool isExpanded) {
                  if (isExpanded && listHotNode == null) {
                    // 获取最热节点
                    getHotNodes();
                  }
                },
                children: <Widget>[
                  (listHotNode != null && listHotNode.isNotEmpty)
                      ? Wrap(
                          children: listHotNode.map((NodeItem node) {
                            return ActionChip(
                                label: Text(node.nodeName),
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NodeTopics(
                                              node.nodeId,
                                              nodeName: node.nodeName,
                                            ))));
                          }).toList(),
                          spacing: 5,
                          runSpacing: -5,
                        )
                      : (listHotNode == null)
                          ? Column(
                              children: <Widget>[
                                CupertinoActivityIndicator(),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text('最热节点...'),
                                ),
                              ],
                            )
                          : Padding(
                              padding: EdgeInsets.all(4),
                              child: Text('获取失败... 😞'),
                            ),
                ],
              ),
              ListTile(
                leading: Icon(Icons.search),
                title: Text(S.of(context).search),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  showSearch(
                      context: context, delegate: SearchSov2exDelegate());
                },
              ),
              Divider(
                height: 0,
              ),
              ListTile(
                enabled: userName.isNotEmpty,
                // 登录后打开
                leading: Icon(Icons.notifications),
                title: Text(S.of(context).notifications),
                trailing: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    notificationCount,
                  ),
                ),
                onTap: () {
                  SpHelper.sp.setString(SP_NOTIFICATION_COUNT, '');
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationPage()));
                },
              ),
              // 自定义的 ExpansionTile
              ExpansionTileDrawerFav(
                isLogin: userName.isNotEmpty,
                leading: Icon(Icons.star),
                title: Text(S.of(context).favorites),
                onExpansionChanged: (bool isExpanded) {
                  if (isExpanded && listFavNode == null) {
                    // 获取收藏的节点
                    getFavouriteNodes();
                  }
                },
                children: <Widget>[
                  listFavNode == null
                      ? Column(
                          children: <Widget>[
                            CupertinoActivityIndicator(),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text('获取收藏节点...'),
                            ),
                          ],
                        )
                      : (listFavNode.isNotEmpty)
                          ? ListView.separated(
                              padding: EdgeInsets.all(0),
                              separatorBuilder: (context, index) => Divider(
                                    height: 0,
                                    indent: 12,
                                    endIndent: 12,
                                  ),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount:
                                  listFavNode != null ? listFavNode.length : 0,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: CachedNetworkImage(
                                    imageUrl: listFavNode[index].img,
                                    fit: BoxFit.fill,
                                    width: 30,
                                    height: 30,
                                  ),
                                  title: Text(listFavNode[index].nodeName),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                  ),
                                  onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => NodeTopics(
                                                listFavNode[index].nodeId,
                                                nodeName:
                                                    listFavNode[index].nodeName,
                                                nodeImg: listFavNode[index].img,
                                              ))),
                                );
                              })
                          : Padding(
                              padding: EdgeInsets.all(4),
                              child: Text('未获取到收藏的节点～'),
                            ),
                ],
              ),
              ListTile(
                enabled: userName.isNotEmpty, // 登录后打开
                leading: Icon(Icons.child_care),
                title: Text(S.of(context).following),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FollowingPage()));
                },
              ),
              ListTile(
                enabled: userName.isNotEmpty,
                leading: Icon(Icons.add),
                title: Text(S.of(context).create),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  // TODO
                  // Navigator.push(
                  //     context,
                  //     new MaterialPageRoute(
                  //         builder: (context) => new NewTopicPage(),
                  //         fullscreenDialog: true));
                },
              ),
              Divider(
                height: 0,
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text(S.of(context).settings),
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SettingPage()));
                },
              ),
              AboutListTile(
                icon: Icon(Icons.info),
                child: Text(S.of(context).about),
                applicationName: "V2LF",
                applicationVersion: "v2020.9",
                applicationLegalese: '© 2020 Wml',
                applicationIcon: Image.asset(
                  "assets/images/icon/ic_launcher.png",
                  width: 64.0,
                  height: 64.0,
                ),
                aboutBoxChildren: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: RichText(
                        text: TextSpan(
                      children: [
                        TextSpan(
                            style: aboutTextStyle,
                            text:
                                "V2LF is a v2ex unofficial app.'V2LF' means 'way to love flutter'.\n\nTo see the progress for this project, please visit the "),
                        _LinkTextSpan(
                          style: linkStyle,
                          url: 'https://trello.com/b/YPOJsfQx/v2lf',
                          text: 'v2lf roadmap',
                        ),
                        TextSpan(
                          style: aboutTextStyle,
                          text: '.\n\n¯\\_(ツ)_/¯',
                        ),
                      ],
                    )),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void checkDailyAward() {
    DioWeb.checkDailyAward().then((onValue) {
      if (!onValue) {
        DioWeb.dailyMission();
        print('准备去领取奖励...');
      } else {
        print('已经领过奖励了...');
      }
    });
  }

  checkLoginState() {
    print('wml：checkLoginState');
    if (SpHelper.sp.containsKey(SP_USERNAME)) {
      userName = SpHelper.sp.getString(SP_USERNAME);
      var avatarUrl = SpHelper.sp.getString(SP_AVATAR);
      avatar = Utils.avatarLarge(
          avatarUrl.startsWith('https:') ? avatarUrl : 'https:' + avatarUrl);
      // 显示诗词
      getOnePoem();
      // 显示未读通知数目
      if (SpHelper.sp.getString(SP_NOTIFICATION_COUNT) != null) {
        notificationCount = SpHelper.sp.getString(SP_NOTIFICATION_COUNT);
      }
    }
  }

  Future getOnePoem() async {
    String today = DateTime.now().toString().substring(0, "yyyy-MM-dd".length);
    print('今天是：' + today);
    var spPoem = SpHelper.sp.getStringList(SP_TODAY_POEM);
    if (spPoem != null && spPoem[0] == today) {
      setState(() {
        poemOne = Poem.fromJson(json.decode(spPoem[1]));
      });
    } else {
      var poem = await NetworkApi.getPoem();
      // 存入 sp
      print(json.encode(poem.toJson()));
      SpHelper.sp
          .setStringList(SP_TODAY_POEM, [today, json.encode(poem.toJson())]);
      if (!mounted) return;
      setState(() {
        if (poem != null) poemOne = poem;
      });
    }
  }

  Future getFavouriteNodes() async {
    var list = await DioWeb.getFavNodes();
    if (!mounted) return;
    setState(() {
      listFavNode = list;
    });
  }

  Future getHotNodes() async {
    var list = await DioWeb.getHotNodes();
    if (!mounted) return;
    setState(() {
      listHotNode = list;
    });
  }
}

class _LinkTextSpan extends TextSpan {
  _LinkTextSpan({TextStyle style, String url, String text})
      : super(
            style: style,
            text: text ?? url,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launch(url,
                    statusBarBrightness:
                        Platform.isIOS ? Brightness.light : null);
              });
}
