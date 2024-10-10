
import 'kline_entity.dart';

class InfoWindowEntity {
  KlineEntity kLineEntity;
  bool isLeft;

  InfoWindowEntity(
    this.kLineEntity, {
    this.isLeft = false,
  });
}
