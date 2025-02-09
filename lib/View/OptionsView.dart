// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';

import 'package:rpmlauncher/Model/UI/ViewOptions.dart';

class OptionsView extends StatefulWidget {
  final List<Widget> Function(StateSetter) optionWidgets;
  final ViewOptions Function() options;
  final List<double?>? weights;
  final List<WeightLimit?>? limits;
  final double gripSize;

  const OptionsView({
    Key? key,
    required this.optionWidgets,
    required this.options,
    this.weights,
    this.limits,
    required this.gripSize,
  }) : super(key: key);

  @override
  State<OptionsView> createState() => _OptionsViewState();
}

class _OptionsViewState extends State<OptionsView> {
  final PageController _pageController = PageController(initialPage: 0);
  int selectedIndex = 0;
  bool pageIsScrolling = false;

  Future<void> _animateToPage(int index) async {
    try {
      int? page = _pageController.page?.toInt();
      if (page != null && ((page - index == 1) || page - index == -1)) {
        await _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.jumpToPage(index);
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll(double offset) {
    if (pageIsScrolling == false) {
      pageIsScrolling = true;
      if (offset > 0) {
        _pageController
            .nextPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut)
            .then((value) => pageIsScrolling = false);
      } else {
        _pageController
            .previousPage(
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut)
            .then((value) => pageIsScrolling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SplitView(
        children: [
          StatefulBuilder(builder: (context, setOptionState) {
            return ListView.builder(
                itemCount: widget.options.call().length,
                itemBuilder: (context, index) {
                  ViewOptionTile option = widget.options.call().options[index];
                  late Widget _optionWidget;

                  if (!option.show) {
                    _optionWidget = SizedBox.shrink();
                  } else {
                    _optionWidget = ListTile(
                      title: Text(option.title!),
                      leading: option.icon,
                      onTap: () async {
                        selectedIndex = index;
                        setOptionState(() {});
                        // _pageController.jumpToPage(index);
                        await _animateToPage(index);
                      },
                      tileColor: selectedIndex == index
                          ? Colors.white12
                          : Theme.of(context).scaffoldBackgroundColor,
                      trailing: Builder(builder: (context) {
                        if (option.description != null) {
                          return Tooltip(
                            message: option.description!,
                            child: Icon(Icons.help),
                          );
                        } else {
                          return SizedBox();
                        }
                      }),
                    );
                  }

                  return _optionWidget;
                });
          }),
          StatefulBuilder(builder: (context, setPageState) {
            // return Listener(
            //   onPointerSignal: (pointerSignal) {
            //     if (pointerSignal is PointerScrollEvent) {
            //       _onScroll(pointerSignal.scrollDelta.dy);
            //     }
            //   },);
            return PageView(
              physics: NeverScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              controller: _pageController,
              children: widget.optionWidgets.call(setPageState),
            );
          })
        ],
        gripSize: 3,
        controller: SplitViewController(
            weights: widget.weights ?? [0.2, 0.8],
            limits: widget.limits ??
                [WeightLimit(max: 0.2, min: 0.1), WeightLimit()]),
        viewMode: SplitViewMode.Horizontal);
  }
}

class OptionPage extends StatefulWidget {
  final Widget mainWidget;
  final List<Widget> actions;

  const OptionPage({
    Key? key,
    required this.mainWidget,
    required this.actions,
  }) : super(key: key);

  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  @override
  Widget build(BuildContext context) {
    return SplitView(
      children: [
        widget.mainWidget,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: widget.actions,
        )
      ],
      viewMode: SplitViewMode.Vertical,
      gripSize: 0,
      controller: SplitViewController(
          weights: [0.92], limits: [WeightLimit(max: 0.92, min: 0.92)]),
    );
  }
}
