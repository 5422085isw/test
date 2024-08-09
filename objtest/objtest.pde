ImageProcessor imgProcessor;
MistakeDetector mistakeDetector;
MistakeDrawer mistakeDrawer;
StartScreen startScreen; // スタート画面のインスタンス
UI ui; // UIのインスタンス追加
ClearScreen clearScreen; // クリア画面のインスタンス
StageSelectScreen stageSelectScreen; // ステージ選択画面のインスタンス
int screen = 0; // 0: start screen, 1: game screen, 2: clear screen, 3: stage select screen
int startTime; // ゲーム開始時刻
String selectedStage = "1-1"; // 選択されたステージ

void setup() {
  size(800, 500);  // ウィンドウサイズを設定
  startScreen = new StartScreen(); // スタート画面のインスタンスを作成
  stageSelectScreen = new StageSelectScreen(); // ステージ選択画面のインスタンスを作成
}

void draw() {
  if (screen == 0) {
    startScreen.display(); // スタート画面を描画
  } else if (screen == 1) {
    stageSelectScreen.display(); // ステージ選択画面を描画
  } else if (screen == 2) {
    if (imgProcessor == null) {
      // ステージに応じて画像を選択
      String image1Path, image2Path;
      int totalMistakes;

      if (selectedStage.equals("1-1")) {
        image1Path = "image1.png";
        image2Path = "image2.png";
        totalMistakes = 3;  // ステージ1-1の間違いの数
      } else if (selectedStage.equals("1-2")) {
        image1Path = "image3.png";
        image2Path = "image4.png";
        totalMistakes = 3;  // ステージ1-2の間違いの数
      } else {
        image1Path = "default1.png";  // デフォルトの画像
        image2Path = "default2.png";  // デフォルトの画像
        totalMistakes = 3;  // デフォルトの間違いの数
      }

      imgProcessor = new ImageProcessor(image1Path, image2Path, 400, 400);
      mistakeDetector = new MistakeDetector(imgProcessor.getResizedImg1(), imgProcessor.getResizedImg2(), 5, 10);
      mistakeDrawer = new MistakeDrawer(mistakeDetector.getFoundAreas(), 10, 2);
      ui = new UI(totalMistakes); // ステージに応じた間違いの数を設定
      startTime = millis(); // ゲーム開始時刻を記録
      imgProcessor.findDifferences();
    }
    drawGameScreen(); // ゲーム画面を描画
    
    // ゲームクリアの判定
    if (ui.getFoundMistakes() >= ui.getTotalMistakes()) {
      screen = 3; // クリア画面に遷移
      clearScreen = new ClearScreen(millis() - startTime, ui.getMissCount()); // クリア画面のインスタンス作成
    }
  } else if (screen == 3) {
    clearScreen.display(); // クリア画面を描画
  }
}

void drawGameScreen() {
  background(255);

  // ゲーム画面を描画（画像は上部の領域に表示）
  image(imgProcessor.getResizedImg1(), 0, 0);
  image(imgProcessor.getResizedImg2(), imgProcessor.getNewWidth(), 0);
  
  // ミスを描画
  mistakeDrawer.drawMistakes();
  
  // UIを描画
  ui.display();
}

void keyPressed() {
  if (key == 'd' && screen == 2) {
    mistakeDetector.toggleShowDifferences();
  }
}

void mousePressed() {
  if (screen == 0 && startScreen.isStartButtonPressed(mouseX, mouseY)) {
    screen = 1; // ステージ選択画面に切り替え
    stageSelectScreen = new StageSelectScreen(); // ステージ選択画面のインスタンスを作成
  } else if (screen == 1) {
    // ステージ選択画面でのボタン処理
    if (stageSelectScreen.isStageButtonPressed(mouseX, mouseY, "1-1")) {
      selectedStage = "1-1";
      screen = 2; // ゲーム画面に切り替え
    } else if (stageSelectScreen.isStageButtonPressed(mouseX, mouseY, "1-2")) {
      selectedStage = "1-2";
      screen = 2; // ゲーム画面に切り替え
    }
  } else if (screen == 2) {
    // 画像2のクリック位置を取得
    int clickX = mouseX - imgProcessor.getNewWidth();  // 画像2は画面の右側に表示されている
    int clickY = mouseY;
    
    // クリック位置が画像2内であるか確認
    if (clickX >= 0 && clickX < imgProcessor.getNewWidth() && clickY >= 0 && clickY < imgProcessor.getNewHeight()) {
      boolean found = mistakeDetector.checkAndRecordMistake(clickX, clickY);
      
      if (found) {
        ui.incrementFound(); // 見つけた間違いをカウント
      } else {
        ui.incrementMiss(); // ミスをカウント
      }
    } else {
      ui.outOfScope();
    }
  } else if (screen == 3) {
    // スタート画面に戻るボタンのクリック位置を確認
    if (clearScreen.isBackButtonPressed(mouseX, mouseY)) {
      screen = 0; // スタート画面に戻る
      imgProcessor = null; // 画像処理インスタンスをリセット
      mistakeDetector = null;
      mistakeDrawer = null;
      ui = null;
      clearScreen = null;
    }
  }
}

// 見つけたエリアを管理するクラス
class CircleArea {
  float x, y, radius;
  
  CircleArea(float x, float y, float radius) {
    this.x = x;
    this.y = y;
    this.radius = radius;
  }
}

// 画像処理を担当するクラス
class ImageProcessor {
  PImage img1, img2;
  PImage resizedImg1, resizedImg2;
  PImage diffImg;
  int newWidth, newHeight;
  
  ImageProcessor(String img1Path, String img2Path, int width, int height) {
    img1 = loadImage(img1Path);
    img2 = loadImage(img2Path);
    newWidth = width;
    newHeight = height;
    
    // 画像をリサイズ
    resizedImg1 = img1.copy();
    resizedImg2 = img2.copy();
    resizedImg1.resize(newWidth, newHeight);
    resizedImg2.resize(newWidth, newHeight);
    
    // Difference imageを生成する
    diffImg = createImage(newWidth, newHeight, RGB);
  }
  
  void findDifferences() {
    resizedImg1.loadPixels();
    resizedImg2.loadPixels();
    diffImg.loadPixels();
    
    for (int i = 0; i < resizedImg1.pixels.length; i++) {
      if (resizedImg1.pixels[i] != resizedImg2.pixels[i]) {
        diffImg.pixels[i] = color(255, 0, 0);  // 赤色で違いを表示
      } else {
        diffImg.pixels[i] = color(255);  // 白色（同じ部分）
      }
    }
    
    diffImg.updatePixels();
  }
  
  PImage getResizedImg1() {
    return resizedImg1;
  }
  
  PImage getResizedImg2() {
    return resizedImg2;
  }
  
  PImage getDiffImg() {
    return diffImg;
  }
  
  int getNewWidth() {
    return newWidth;
  }
  
  int getNewHeight() {
    return newHeight;
  }
}

// 間違いの検出を担当するクラス
class MistakeDetector {
  PImage img1, img2;
  ArrayList<PVector> mistakes = new ArrayList<PVector>();
  ArrayList<CircleArea> foundAreas = new ArrayList<CircleArea>();
  float mistakeRadius;  // 判定半径
  float foundRadius;    // 既に見つけたエリアの半径
  boolean showDifferences = false;

  MistakeDetector(PImage img1, PImage img2, float mistakeRadius, float foundRadius) {
    this.img1 = img1;
    this.img2 = img2;
    this.mistakeRadius = mistakeRadius;
    this.foundRadius = foundRadius;
  }

  boolean checkAndRecordMistake(float clickX, float clickY) {
    boolean found = false;

    // 判定半径を設定
    float searchRadius = mistakeRadius; // クリック位置からの検索半径を設定

    for (float x = clickX - searchRadius; x <= clickX + searchRadius; x++) {
      for (float y = clickY - searchRadius; y <= clickY + searchRadius; y++) {
        if (dist(clickX, clickY, x, y) <= searchRadius) {
          color colorImg1 = img1.get((int)x, (int)y);
          color colorImg2 = img2.get((int)x, (int)y);

          if (colorImg1 != colorImg2) {
            boolean alreadyFound = false;

            for (CircleArea area : foundAreas) {
              if (dist(x, y, area.x, area.y) <= foundRadius * 4) {
                alreadyFound = true;
                break;
              }
            }

            if (!alreadyFound) {
              PVector clickPos = new PVector(x, y);
              if (!mistakes.contains(clickPos)) {
                mistakes.add(clickPos);
                found = true;
                // 新しく見つけた間違いを記録する
                foundAreas.add(new CircleArea(x, y, foundRadius));
              }
            }
          }
        }
      }
    }

    return found;
  }

  void toggleShowDifferences() {
    showDifferences = !showDifferences;
  }

  PImage getDiffImg() {
    return imgProcessor.getDiffImg();
  }

  ArrayList<CircleArea> getFoundAreas() {
    return foundAreas;
  }
}

// 間違いを描画するクラス
class MistakeDrawer {
  ArrayList<CircleArea> foundAreas;
  float circleRadius;
  float strokeWidth;
  
  MistakeDrawer(ArrayList<CircleArea> foundAreas, float circleRadius, float strokeWidth) {
    this.foundAreas = foundAreas;
    this.circleRadius = circleRadius;
    this.strokeWidth = strokeWidth;
  }
  
  void drawMistakes() {
    for (CircleArea area : foundAreas) {
      // 赤い円
      noFill();
      stroke(255, 0, 0); // 赤い色
      strokeWeight(strokeWidth); // 円の線の太さ
      ellipse(area.x + imgProcessor.getNewWidth(), area.y, area.radius * 2, area.radius * 2); // 赤い丸で囲む
    }
  }
  
  float getCircleRadius() {
    return circleRadius;
  }
}

// UIを担当するクラス
class UI {
  int totalMistakes;  // 見つけるべき間違いの総数
  int foundMistakes;  // 見つけた間違いの数
  int missCount;      // ミスの回数
  int padding = 10;   // テキストと背景の余白
  int marginLeft = 15; // 左側の余白
  String message = ""; // メッセージ表示用の変数

  UI(int totalMistakes) {
    this.totalMistakes = totalMistakes;
    this.foundMistakes = 0;
    this.missCount = 0;
  }
  
  void incrementFound() {
    if(foundMistakes < totalMistakes){
      foundMistakes++;
      message = "You find a mistake!";
    }
  }

  void incrementMiss() {
    missCount++;
    message = "This is not mistake or already found it";
  }
  
  void outOfScope(){
    message = "This is correct image";
  }
  
  void display() {
    textSize(24);
    textAlign(LEFT, TOP); // テキストを左上に揃える
    
    // テキストの横幅と高さを計算
    float remainingTextWidth = textWidth("Remaining: " + (totalMistakes - foundMistakes));
    float missesTextWidth = textWidth("Misses: " + missCount);
    float textHeight = textAscent() + textDescent(); // テキストの高さを計算

    // 文字の描画
    fill(0); // 黒色
    text("Remaining: " + (totalMistakes - foundMistakes), marginLeft + padding, height - 100 + padding);
    text("Misses: " + missCount, marginLeft + padding, height - 100 + padding + textHeight + padding);
    text(message,marginLeft + padding,height - 100 + padding + 2 * (textHeight + padding));
  }
  
  int getFoundMistakes() {
    return foundMistakes;
  }
  
  int getTotalMistakes() {
    return totalMistakes;
  }
  
  int getMissCount() {
    return missCount;
  }
  
  void setMessage(String newMessage){
    message = newMessage;
  }
}

// スタート画面を担当するクラス
class StartScreen {
  int buttonX, buttonY, buttonWidth, buttonHeight;

  StartScreen() {
    // スタートボタンの位置とサイズを設定
    buttonX = width / 2;
    buttonY = height / 2 + 50;
    buttonWidth = 200;
    buttonHeight = 50;
  }

  void display() {
    background(50, 100, 200); // 背景色を設定
    
    noStroke();
    fill(255); // テキストの色を設定
    textSize(48); // テキストサイズを設定
    textAlign(CENTER, CENTER); // テキストの位置を中央に揃える
    text("Can you find mistakes?", width / 2, height / 2 - 100); // タイトルテキスト

    // スタートボタン
    fill(0, 150, 0); // ボタンの色を設定
    rectMode(CENTER);
    rect(buttonX, buttonY, buttonWidth, buttonHeight);

    fill(255); // ボタンのテキストの色
    textSize(24);
    text("Start", buttonX, buttonY);
  }

  boolean isStartButtonPressed(int mouseX, int mouseY) {
    // ボタンがクリックされたか確認
    return mouseX > buttonX - buttonWidth / 2 && mouseX < buttonX + buttonWidth / 2 &&
           mouseY > buttonY - buttonHeight / 2 && mouseY < buttonY + buttonHeight / 2;
  }
}

// クリア画面を担当するクラス
class ClearScreen {
  int elapsedTime; // 経過時間（ミリ秒）
  int missCount;   // ミスの回数
  int buttonX, buttonY, buttonWidth, buttonHeight;

  ClearScreen(int elapsedTime, int missCount) {
    this.elapsedTime = elapsedTime;
    this.missCount = missCount;
    buttonX = width / 2;
    buttonY = height / 2 + 100;
    buttonWidth = 200;
    buttonHeight = 50;
  }

  void display() {
    background(50, 100, 200); // 背景色を設定
    
    noStroke();
    fill(255); // テキストの色を設定
    textSize(48); // テキストサイズを設定
    textAlign(CENTER, CENTER); // テキストの位置を中央に揃える
    text("Clear", width / 2, height / 2 - 50); // 「Clear」テキスト

    textSize(24);
    text("Time: " + (elapsedTime / 1000.0) + " seconds", width / 2, height / 2 + 10); // 経過時間
    text("Misses: " + missCount, width / 2, height / 2 + 50); // ミスの回数

    // スタート画面に戻るボタン
    fill(150, 0, 0); // ボタンの色を設定
    rectMode(CENTER);
    rect(buttonX, buttonY, buttonWidth, buttonHeight);

    fill(255); // ボタンのテキストの色
    textSize(24);
    text("Back to Start", buttonX, buttonY);
  }

  boolean isBackButtonPressed(int mouseX, int mouseY) {
    // ボタンがクリックされたか確認
    return mouseX > buttonX - buttonWidth / 2 && mouseX < buttonX + buttonWidth / 2 &&
           mouseY > buttonY - buttonHeight / 2 && mouseY < buttonY + buttonHeight / 2;
  }
}

// ステージ選択画面を担当するクラス
class StageSelectScreen {
  int buttonX1, buttonY1, buttonWidth, buttonHeight;
  int buttonX2, buttonY2;

  StageSelectScreen() {
    // ステージ1-1ボタンの位置とサイズを設定
    buttonX1 = width / 2 - 110;
    buttonY1 = height / 2;
    buttonWidth = 200;
    buttonHeight = 50;
    
    // ステージ1-2ボタンの位置を設定
    buttonX2 = width / 2 + 110;
    buttonY2 = height / 2;
  }

  void display() {
    background(50, 100, 200); // 背景色を設定
    
    noStroke();
    fill(255); // テキストの色を設定
    textSize(48); // テキストサイズを設定
    textAlign(CENTER, CENTER); // テキストの位置を中央に揃える
    text("Select a Stage", width / 2, height / 2 - 100); // タイトルテキスト

    // ステージ1-1ボタン
    fill(0, 150, 0); // ボタンの色を設定
    rectMode(CENTER);
    rect(buttonX1, buttonY1, buttonWidth, buttonHeight);

    fill(255); // ボタンのテキストの色
    textSize(24);
    text("1-1", buttonX1, buttonY1);

    // ステージ1-2ボタン
    fill(150, 0, 0); // ボタンの色を設定
    rect(buttonX2, buttonY2, buttonWidth, buttonHeight);

    fill(255); // ボタンのテキストの色
    textSize(24);
    text("1-2", buttonX2, buttonY2);
  }

  boolean isStageButtonPressed(int mouseX, int mouseY, String stage) {
    if (stage.equals("1-1")) {
      return mouseX > buttonX1 - buttonWidth / 2 && mouseX < buttonX1 + buttonWidth / 2 &&
             mouseY > buttonY1 - buttonHeight / 2 && mouseY < buttonY1 + buttonHeight / 2;
    } else if (stage.equals("1-2")) {
      return mouseX > buttonX2 - buttonWidth / 2 && mouseX < buttonX2 + buttonWidth / 2 &&
             mouseY > buttonY2 - buttonHeight / 2 && mouseY < buttonY2 + buttonHeight / 2;
    }
    return false;
  }
}
