import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import './App.css';
import { BigNumber, ethers, utils } from "ethers";
import { ABI } from "./METabi.js";
import { isCommunityResourcable } from '@ethersproject/providers';

let selectedAccount = "Not Connected";
let tokenname = "ERC20";
let textbeforelockaddress;
let accountlockaddress;
let accountlockstatus;
let personallock;
let setaddress;
let contractstatus;
let currentcontract;
let currentstatus = "undefined";
let morevariable = "closed";

if (typeof window.ethereum !== 'undefined') {
  console.log('MetaMask is installed!');
}

let tokenaddress = "0x4137c5c693E16F9B355B662737e6Fb6EB3398AD7";
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
let tokenContract = new ethers.Contract(tokenaddress, ABI, signer);
let tokenWithSigner = tokenContract.connect(signer);


class Mainn extends React.Component {
  render() {
    return ( <div>
    <h1> <span key={tokenname} id="tokennamo" className="tokennamo">{tokenname}</span> Multisig Extension  </h1>
    <h3>Your account: <div id="accountdiv"><p id="p3">{selectedAccount}</p></div> </h3>
    <div id="bigdiv" ><p><input type="text" id="contracto" onInput={() => {(checkchangec())}} placeholder="Token Address"></input></p>   
    <p><button id="setter" onClick={() => {(superta())}}> Set contract address </button>
    <span id="minter"><button onClick={() => {(mintMet())}} > Mint </button></span></p>
    <div id="statusdiv"><h4 id="h4"> {accountlockstatus} </h4>
    <h5 id="h5"> {textbeforelockaddress} <p id="multip">{accountlockaddress}</p> </h5></div>
    <p id="multti"><input type="text" id="multiadd" placeholder="New permissioned address"></input>
    <button onClick={() => {(multiadd())}}> Set </button></p>
    <div id="div1" ><p><input type="text" id="setaddress" onInput={() => {(checklock())}} placeholder="Address"></input>
    <button id="lockunlock" onClick={() => {(lockunlock())}} ></button></p>
    <span id="more"><h6 type="text" > Advanced settings </h6>
    <p><input type="text" id="stopamount" onInput={() => {(changestopainput())}} placeholder="Amount"></input>
    <button id="stopabtn" onClick={() => {(stpab())}} > Change </button></p>
    <p id="p1" ><input type="text" id="stoptime" onInput={() => {(changestoptinput())}} placeholder="Time (in seconds)"></input>
    <button id="stoptbtn" onClick={() => {(stptb())}} > Change </button></p>
    <p id="p2"><input type="text" id="astopamount" onInput={() => {(achangestopainput())}} placeholder="Allowed amount change"></input>
    <button id="stopaabtn" onClick={() => {(achangestopa())}} >Change</button></p>
    <p><input type="text" id="astoptime" onInput={() => {(achangestoptinput())}} placeholder="Allwoed time change"></input>
    <button id="stoptabtn" onClick={() => {(achangestopt())}} >Change</button></p></span>
    <p><button onClick={() => {(showmore())}} id="advanced"> Advanced Settings </button></p></div></div>
      </div> ) 
}
}

async function checklock() {
  if(contractstatus != undefined) {
  var lockbtn = document.getElementById("lockunlock");
  setaddress = document.getElementById('setaddress').value;
  let btnText1 = document.getElementById('lockunlock');
  let lockedaddressText = document.getElementById("setaddress");
  if(currentstatus == "undefined") {
  if(ethers.utils.isAddress(setaddress)) {
    personallock = await tokenContract.getpersonallock(setaddress);
    if(personallock == true){
      lockbtn.innerHTML = "Unlock";
      lockedaddressText.style.color = "red";
      lockbtn.style.display = "inline";
    } else {
      lockedaddressText.style.color = "green";
      lockbtn.innerHTML = "Lock";
      lockbtn.style.display = "inline";
    }
} else {
  lockbtn.style.display = "none";
  lockedaddressText.style.color = "black";
}
  } else {
    console.log("Error: No contract specified yet");
  }
}
}

async function lockunlock() {
  if(personallock == false){
    tokenWithSigner.allowunallowtransfer(setaddress, true);
    currentstatus = "undefined";
  }
  else {
    tokenWithSigner.allowunallowtransfer(setaddress, false);
    currentstatus = "undefined";
  }
}

async function showmore() {
  var moreText = document.getElementById("more");
  var btnText2 = document.getElementById("advanced");
  if(morevariable == "closed"){
    moreText.style.display = "inline";
    btnText2.innerHTML = "Close";
    morevariable = "open";
  }
  else {
    moreText.style.display = "none";
    btnText2.innerHTML = "Advanced Settings";
    morevariable = "closed";
  }
  root.render(<Mainn/ >);
  
}

async function changecontract(contracto) {
  tokenaddress = contracto;
}

async function mintMet() {
  tokenWithSigner.mint();
}

async function stpab() {
  let decimals = await tokenContract.decimals();
  setaddress = document.getElementById('setaddress').value;
  let stopa = ((document.getElementById("stopamount").value) * 1e18).toString();
  tokenWithSigner.setstopamount(setaddress, stopa);
}

async function stptb() {
  setaddress = document.getElementById('setaddress').value;
  let stopt = document.getElementById("stoptime").value;
  tokenWithSigner.setstoptime(setaddress, stopt);
}

async function checkchangec() {
  let newcontracttxt = document.getElementById('contracto');
  if(newcontracttxt.value !== currentcontract) {
    contractstatus = "undefined";
    newcontracttxt.style.borderColor = "gray";
    newcontracttxt.style.borderStyle = "dotted";
    newcontracttxt.style.borderWidth = "2px";
  } else {
    contractstatus = "defined";
    newcontracttxt.style.borderColor = "green";
    newcontracttxt.style.borderStyle = "solid";
    newcontracttxt.style.borderWidth = "2px";
  }
}

async function achangestopainput() {
  let stopabtn = document.getElementById("stopaabtn");
  let stopa = document.getElementById("astopamount").value;
  if(isNaN(stopa) || stopa == undefined || stopa.length === 0) {
    stopabtn.innerHTML = "Change";
  } else {
    let status = await tokenContract.returnallowedstopamount(setaddress, selectedAccount, stopa);
    if(status) {
      stopabtn.innerHTML = "Unallow";
      } else {
         stopabtn.innerHTML = "Allow";
  }
}
}

async function achangestopa() {
  let stopabtn = document.getElementById("stopaabtn");
  setaddress = document.getElementById("setaddress").value;
  let astopa = document.getElementById("astopamount").value;
  let boolh;
  if(stopabtn.innerHTML == "Unallow") {
    boolh = false;
  } else {
    boolh = true;
  };
  tokenWithSigner.allowunallowsetstopa(setaddress, astopa, boolh);
}

async function achangestoptinput() {
  let stoptbtn = document.getElementById("stoptabtn");
  let stopt = document.getElementById("astoptime").value;
  if(isNaN(stopt) || stopt == undefined || stopt.length === 0) {
    stoptbtn.innerHTML = "Change";
  } else {
    let status = await tokenContract.returnallowedstoptime(setaddress, selectedAccount, stopt);
    if(status) {
      stoptbtn.innerHTML = "Unallow";
      } else {
         stoptbtn.innerHTML = "Allow";
  }
}
}

async function achangestopt() {
  let stoptbtn = document.getElementById("stoptabtn");
  setaddress = document.getElementById("setaddress").value;
  let astopt = document.getElementById("astoptime").value;
  let boolh;
  if(stoptbtn.innerHTML == "Unallow") {
    boolh = false;
  } else {
    boolh = true;
  };
  tokenWithSigner.allowunallowsetstopt(setaddress, astopt, boolh);
}

async function changestopainput() {
  let stopbtn = document.getElementById("stopabtn");
  let stopa = document.getElementById("stopamount").value;
  if(isNaN(stopa) || stopa == undefined || stopa.length === 0) {
    stopbtn.innerHTML = "Change";
  } else {
      stopbtn.innerHTML = "Set";
      }
}

async function changestoptinput() {
  let stopbtn = document.getElementById("stoptbtn");
  let stopt = document.getElementById("stoptime").value;
  if(isNaN(stopt) || stopt == undefined || stopt.length === 0) {
    stopbtn.innerHTML = "Change";
  } else {
      stopbtn.innerHTML = "Set";
      }
}

async function superta() {
  let h4display = document.getElementById("h4");
  let newcontract = document.getElementById('contracto').value;
  let newcontracttxt = document.getElementById('contracto');
  setaddress = document.getElementById('setaddress').value;
  const accounts = await provider.send("eth_requestAccounts", []);
  selectedAccount = accounts[0];
  changecontract(newcontract);
  tokenContract = tokenContract.attach( tokenaddress );
  tokenWithSigner = tokenContract.connect(signer);
  tokenname = await tokenContract.name();
  let lockstatus = await tokenContract.getlockstatus(selectedAccount);
  if(lockstatus != false) {
    accountlockstatus = "Locked";
    h4display.style.color = "green";
    } else {
      accountlockstatus = "Not locked";
      h4display.style.color = "red";
    };
  textbeforelockaddress = "Your permissioned address (for this token):"
  let csendermulti = await tokenContract.getlockaddress(selectedAccount);
  if(csendermulti === "0x0000000000000000000000000000000000000000") {
    accountlockaddress = "You have no multiaddress set yet";
  } else {
    accountlockaddress = csendermulti;
  }
  newcontracttxt.style.border = "solid";
  newcontracttxt.style.borderColor = "green";
  currentcontract = newcontract;
  let mintbtn = document.getElementById("minter");
  if(tokenaddress == "0x4137c5c693E16F9B355B662737e6Fb6EB3398AD7") {
    mintbtn.style.display = "inline";
  } else {
    mintbtn.style.display = "none";
  };
  contractstatus = "defined";
  root.render(<Mainn/ >);

}

async function multiadd() {
  let newadd = document.getElementById('multiadd').value; 
  tokenWithSigner.setlockaddress(selectedAccount, newadd);
}

getNote();

async function getNote() {
  const accounts = await provider.send("eth_requestAccounts", []);
  selectedAccount = accounts[0];
  root.render(<Mainn/ >);
}

tokenContract.on("transferallowed", (from, to, allowance) => {
    superta();
    checklock();
});

tokenContract.on("lockaddressset", (to, newaddresss) => {
    superta();
});


const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Mainn/ >);
